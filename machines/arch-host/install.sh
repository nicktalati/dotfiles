#!/bin/bash

set -Eeuo pipefail
exec > >(tee -i "/tmp/install-$(date +%Y%m%d.%H-%M-%S).log") 2>&1

readonly df_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
readonly machine_dir="$df_dir/machines/arch-host"
readonly stow_dir="$df_dir/stow"
readonly pkglist="$machine_dir/packages.txt"

readonly xdg_conf="$HOME/.config"
readonly oauth_dir="$HOME/.local/share/mail/oauth"

red="\033[31m"
yellow="\033[33m"
reset="\033[0m"
configure_only=false

log() { echo -e "$(date +%T): $1"; }
info() { log "INFO: $1"; }
warn() { log "${yellow}WARNING:${reset} $1"; }
error() { log "${red}FATAL:${reset} $1"; exit 1; }

usage() {
    cat <<'EOF'
Usage: install.sh [--configure-only]

  --configure-only  Restow and render home configuration without installing
                    packages, writing /etc, configuring Firefox, changing the
                    login shell, prompting for secrets, or enabling services.
EOF
}

ensure_commands() {
    for cmd in "$@"; do
        command -v "$cmd" &> /dev/null || error "Command is not available: $cmd"
    done
}

while (($#)); do
    case "$1" in
        --configure-only)
            configure_only=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            error "Unknown argument: $1"
            ;;
    esac
    shift
done

# checks
[[ "$EUID" -ne 0 ]] || error "Script must not be run as root."
grep -iqs "ID=arch" "/etc/os-release" || error "System is not Arch."

[[ -d "$df_dir" ]] || error "Directory does not exist: $df_dir"
[[ -d "$stow_dir" ]] || error "Directory does not exist: $stow_dir"
[[ -f "$pkglist" ]] || error "File does not exist: $pkglist"
ensure_commands stow

if ! $configure_only; then
    ensure_commands pacman sudo
    sudo -v || error "This script requires sudo privileges."

    # sudo loop so no reauth
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done &>/dev/null &
fi

# ~/downloads is declared in user-dirs.dirs; Firefox and shot save there.
mkdir -p "$HOME/mail" "$HOME/downloads" "$oauth_dir"
chmod 700 "$oauth_dir"
# NeoMutt's sidebar section headers are local-only pseudo-Maildirs no program
# creates: mbsync only creates mailboxes that exist remotely.
mkdir -p "$HOME"/mail/.header-{cultivate,nicktalati}/{cur,new,tmp}

if ! $configure_only; then
    # bootstrap yay
    if ! command -v yay &> /dev/null; then
        info "Installing yay..."
        git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
        (cd /tmp/yay-bin && makepkg -si --noconfirm)
        rm -rf /tmp/yay-bin
    fi

    info "Installing packages from $pkglist..."
    yay -S --needed - < "$pkglist"
fi

info "Stowing dotfiles..."
stow -v -R --no-folding -d "$stow_dir" -t "$HOME" \
    shell nvim tmux git mail psql task backup arch-desktop wallpaper \
    account-cultivate account-personal

mkdir -p "$xdg_conf/dotfiles"
printf '%s\n' arch-host > "$xdg_conf/dotfiles/machine"
if $configure_only; then
    "$machine_dir/firefox/setup.sh" --user-only
    info "Arch host configuration complete."
    exit 0
fi

info "Copying /etc files..."
sudo mkdir -p /etc/{iwd,keyd}
sudo cp "$machine_dir/etc/iwd/main.conf" "/etc/iwd/main.conf"
sudo cp "$machine_dir/etc/keyd/default.conf" "/etc/keyd/default.conf"

info "Setting up Firefox profiles..."
"$machine_dir/firefox/setup.sh"

# change shell
if ! command -v zsh &> /dev/null; then
    warn "zsh not found; not changing shell."
elif [[ "$SHELL" != "$(command -v zsh)" ]]; then
    info "Changing shell to zsh..."
    sudo chsh -s "$(command -v zsh)" "$USER"
fi

# systemd units
info "Enabling Systemd Units..."

systemctl --user daemon-reload
systemctl --user disable mbsync.timer goimapnotify@goimapnotify.service 2>/dev/null || true
for account in cultivate personal; do
    systemctl --user enable "mbsync@$account.timer"
    systemctl --user enable "goimapnotify@$account.service"
done
systemctl --user enable backup.timer
systemctl --user enable ssh-agent.service

sudo systemctl daemon-reload
sudo systemctl enable earlyoom
sudo systemctl enable iwd.service
sudo systemctl enable keyd.service
sudo systemctl enable bluetooth.service
sudo systemctl enable systemd-timesyncd.service
sudo systemctl enable tlp.service

cat <<'EOF'
=========================================================
                  INSTALLATION COMPLETE
=========================================================
  1. Create ~/.config/restic/env from Bitwarden (see README)
  2. Reboot
=========================================================
EOF
