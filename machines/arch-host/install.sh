#!/bin/bash

set -Eeuo pipefail
exec > >(tee -i "/tmp/install-$(date +%Y%m%d.%H-%M-%S).log") 2>&1

readonly df_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
readonly machine_dir="$df_dir/machines/arch-host"
readonly stow_dir="$df_dir/stow"
readonly pkglist="$machine_dir/packages.txt"

readonly decrypt_dir="$HOME/decrypt"
readonly decrypt_secrets="$decrypt_dir/secrets"

readonly xdg_state="$HOME/.local/state"
readonly xdg_conf="$HOME/.config"
readonly oauth_dir="$HOME/.local/share/mail/oauth"

readonly rclone_tmpl="$stow_dir/arch-vault/.config/rclone/rclone.conf.template"
readonly rclone_conf="$xdg_conf/rclone/rclone.conf"
readonly gcfs_conf="$xdg_conf/gocryptfs/secrets"

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

mkdir -p "$xdg_state"/{nvim/undo,python,node,psql,zsh,msmtp}
mkdir -p "$HOME/downloads" "$HOME/mail" "$oauth_dir"
chmod 700 "$oauth_dir"

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
    shell nvim tmux git mail psql task arch-vault arch-backup arch-desktop \
    account-cultivate account-personal account-paypal

mkdir -p "$xdg_conf/dotfiles" "$xdg_conf/neomutt" \
    "$xdg_conf/notmuch/default" "$xdg_conf/zsh"
printf '%s\n' arch-host > "$xdg_conf/dotfiles/machine"
printf '%s\n' cultivate personal paypal > "$xdg_conf/dotfiles/accounts"

cat > "$xdg_conf/neomutt/accounts.rc" <<'EOF'
set spoolfile = "+cultivate/Inbox"
source ~/.config/neomutt/accounts/cultivate.rc
source ~/.config/neomutt/accounts/personal.rc
source ~/.config/neomutt/accounts/paypal.rc
EOF

cat > "$xdg_conf/notmuch/default/config" <<EOF
[database]
path=$HOME/mail

[user]
name=Nick Talati
primary_email=talati@getcultivate.ai
other_email=nicktalati@gmail.com;nicktalatipaypal@gmail.com

[new]
tags=
ignore=.mbsyncstate;.uidvalidity

[search]

[maildir]
EOF

for account in cultivate personal paypal; do
    while IFS= read -r mailbox; do
        mkdir -p "$HOME/mail/$mailbox"/{cur,new,tmp}
    done < <(
        sed -n 's/^named-mailboxes "[^"]*" "+\([^"]*\)"$/\1/p' \
            "$xdg_conf/neomutt/accounts/$account.rc"
    )
done

mkdir -p "$HOME/.ssh/config.d"
if ! $configure_only; then
    info "Setting up secrets..."
    mkdir -p "$xdg_conf"/{rclone,gocryptfs}
    if [[ ! -f "$gcfs_conf" ]]; then
        echo -n "Gocryptfs password: "
        read -rs gcfs_pass
        echo
        echo "$gcfs_pass" > "$gcfs_conf"
        chmod 600 "$gcfs_conf"
    fi

    [[ -f "$rclone_tmpl" ]] || error "Template missing: $rclone_tmpl"
    [[ -f "$rclone_conf" ]] || install -m 600 "$rclone_tmpl" "$rclone_conf"
fi

# These links are broken until decrypt is mounted by gocryptfs. Public SSH keys
# and host configuration are ordinary account-package files; only private keys
# remain in the legacy vault.
ln -sfn "$decrypt_secrets/secrets.zsh" "$xdg_conf/zsh/secrets.zsh"
ln -sfn "$decrypt_secrets/oauth/cultivate.oauth2" "$oauth_dir/cultivate"
ln -sfn "$decrypt_secrets/oauth/nicktalati.oauth2" "$oauth_dir/personal"
ln -sfn "$decrypt_secrets/oauth/nicktalatipaypal.oauth2" "$oauth_dir/paypal"
ln -sfn "$decrypt_secrets/ssh/id_rsa_personal" "$HOME/.ssh/id_rsa_personal"
ln -sfn "$decrypt_secrets/ssh/id_rsa_work_github" "$HOME/.ssh/id_rsa_work_github"
ln -sfn "$decrypt_secrets/ssh/id_rsa_work_gitlab" "$HOME/.ssh/id_rsa_work_gitlab"
ln -sfn "$decrypt_secrets/ssh/greenville.pem" "$HOME/.ssh/greenville.pem"

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
for account in cultivate personal paypal; do
    systemctl --user enable "mbsync@$account.timer"
    systemctl --user enable "goimapnotify@$account.service"
done
systemctl --user enable zsh-hist-backup.timer
systemctl --user enable crypt-backup.timer
systemctl --user enable crypt-mount.service
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
  1. Update ~/.config/rclone/rclone.conf
  2. Run 'rclone sync crypt:talati-crypt/crypt ~/crypt'
  3. Reboot
=========================================================
EOF
