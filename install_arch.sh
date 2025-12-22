#!/bin/bash

# need to ensure absolute idempotency

set -Eeuo pipefail

exec > >(tee -i "$(date +%Y%m%d.%H-%M-%S).log") 2>&1

trap 'unxp_fail "$LINENO" "$BASH_COMMAND" "$?"' ERR

red="\033[31m"
yellow="\033[33m"
reset="\033[0m"

log() { echo -e "$(date +%T): $1"; }
info() { log "INFO: $1"; }
warn() { log "${yellow}WARNING:${reset} $1"; }
error() { log "${red}FATAL:${reset} $1"; exit 1; }
unxp_fail() { log "${red}UNEXPECTED ERROR:${reset} line $1: '$2' exited with code $3"; exit "$3"; }

ensure_arch() {
    if ! grep -iqs "ID=arch" "/etc/os-release"; then
        error "System is not Arch."
    fi
}
ensure_sudo() {
    if ! sudo -v; then
        error "This script requires sudo privileges."
    fi
}
ensure_commands() {
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "Command is not available: $cmd"
        fi
    done
}
ensure_dir() { [[ -d "$1" ]] || error "Directory does not exist: $1"; }
ensure_file() { [[ -f "$1" ]] || error "File does not exist: $1"; }

cp_template() {
    local src="$1" dest="$2"
    [[ -f "$src" ]] || error "Template missing: $src"
    [[ -f "$dest" ]] && { warn "Secret exists: $dest Skipping..."; return 0; }
    install -m 600 "$src" "$dest" && info "Created $dest"
}


df_dir="$HOME/dotfiles"
df_conf="$df_dir/core/.config"
xdg_state="$HOME/.local/state"
pkglist="$HOME/dotfiles/pkglist.txt"

declare -A secrets_templates=(
    ["$df_conf/zsh/secrets.zsh"]="$df_conf/zsh/secrets.zsh.template"
    ["$df_conf/gocryptfs/secrets"]="$df_conf/gocryptfs/secrets.template"
    ["$df_conf/rclone/rclone.conf"]="$df_conf/rclone/rclone.conf.template"
)

ensure_arch
ensure_commands pacman sudo git
ensure_sudo
ensure_dir "$df_dir"
ensure_dir "$df_conf"
ensure_dir "$xdg_state"
ensure_file "$pkglist"

# hardcoded -- fix (array?)
mkdir -p "$xdg_state/nvim/undo"
mkdir -p "$xdg_state/python"
mkdir -p "$xdg_state/node"
mkdir -p "$xdg_state/psql"
mkdir -p "$xdg_state/zsh"

for secret in "${!secrets_templates[@]}"; do
    template="${secrets_templates[$secret]}"
    cp_template "$template" "$secret"
done

if ! command -v paru &> /dev/null; then
    info "Installing paru..."
    sudo pacman -S --needed base-devel

    trap '[ -n "$temp_dir" ] && rm -rf "$temp_dir"' EXIT
    temp_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru.git "$temp_dir"

    pushd "$temp_dir" # this will trigger the script to halt if it fails right? 
    makepkg -si --noconfirm || error "failed to install paru." # handle failure better?
    popd

    ensure_commands paru

#    rm -rf "$temp_dir" # removed because the trap will always do this right?
else
    info "Paru is already installed."
fi

# need to check if necessary on fresh install
if pacman -Qi iptables &>/dev/null && ! pacman -Qi iptables-nft &>/dev/null; then
    info "Swapping iptables for iptables-nft..."
    yes | sudo pacman -S iptables-nft
fi

info "Installing packages from $pkglist..."
paru -S --needed - < "$pkglist"

ensure_commands stow firefox

info "Stowing dotfiles..."
stow -v -R --no-folding -d "$df_dir" -t "$HOME" core gui

# hardcoded -- fix
info "Copying /etc files..."
sudo mkdir -p /etc/iwd /etc/keyd
sudo cp "$df_dir/etc/iwd/main.conf" "/etc/iwd/main.conf"
sudo cp "$df_dir/etc/keyd/default.conf" "/etc/keyd/default.conf"

# fix
info "Creating firefox profiles..."
firefox -CreateProfile "personal"
firefox -CreateProfile "work"

if [ "$SHELL" != "$(command -v zsh)" ]; then
    if ! command -v zsh &> /dev/null; then
        warn "zsh not found; not changing shell."
    else
        info "Changing shell to zsh..."
        chsh -s "$(command -v zsh)"
    fi
fi

info "Enabling Systemd Units..."

systemctl --user daemon-reload
systemctl --user enable zsh-hist-backup.timer
systemctl --user enable crypt-backup.timer
systemctl --user enable crypt-mount.service
systemctl --user reset-failed

sudo systemctl daemon-reload
sudo systemctl enable iwd
sudo systemctl enable keyd.service
sudo systemctl enable bluetooth.service
sudo systemctl enable systemd-timesyncd.service

info "Adding user to docker group..."

sudo usermod -aG docker "$USER"

echo ""
echo "========================================================="
echo "                  INSTALLATION COMPLETE                  "
echo "========================================================="
echo "  1. Update secrets files:                               "
echo "    - ~/.config/zsh/secrets.zsh                          "
echo "    - ~/.config/gocryptfs/secrets                        "
echo "    - ~/.config/rclone/rclone.conf                       "
echo "  2. Run 'rclone sync crypt:talati-crypt/crypt ~/crypt'  "
echo "  3. Reboot                                              "
echo "========================================================="
