#!/bin/bash
set -Eeuo pipefail
exec > >(tee -i "/tmp/install-$(date +%Y%m%d.%H-%M-%S).log") 2>&1

readonly df_dir="$HOME/dotfiles"
readonly df_conf="$df_dir/core/.config"
readonly pkglist="$df_dir/pkglist.txt"
readonly xdg_state="$HOME/.local/state"

declare -A secrets_templates=(
    ["$df_conf/zsh/secrets.zsh"]="$df_conf/zsh/secrets.zsh.template"
    ["$df_conf/gocryptfs/secrets"]="$df_conf/gocryptfs/secrets.template"
    ["$df_conf/rclone/rclone.conf"]="$df_conf/rclone/rclone.conf.template"
)

red="\033[31m"
yellow="\033[33m"
reset="\033[0m"

log() { echo -e "$(date +%T): $1"; }
info() { log "INFO: $1"; }
warn() { log "${yellow}WARNING:${reset} $1"; }
error() { log "${red}FATAL:${reset} $1"; exit 1; }

ensure_commands() {
    for cmd in "$@"; do
        command -v "$cmd" &> /dev/null || error "Command is not available: $cmd"
    done
}

[[ "$EUID" -ne 0 ]] || error "Script must not be run as root."
ensure_commands pacman sudo
grep -iqs "ID=arch" "/etc/os-release" || error "System is not Arch."

[[ -d "$df_dir" ]] || error "Directory does not exist: $df_dir"
[[ -d "$df_conf" ]] || error "Directory does not exist: $df_conf"
[[ -f "$pkglist" ]] || error "File does not exist: $pkglist"

sudo -v || error "This script required sudo privileges."
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done &>/dev/null &

mkdir -p "$xdg_state"/{nvim/undo,python,node,psql,zsh}

for secret in "${!secrets_templates[@]}"; do
    template="${secrets_templates[$secret]}"
    [[ -f "$template" ]] || error "Template missing: $template"
    if [[ -f "$secret" ]]; then
        warn "Secret exists: $secret. Skipping..."
    else
        install -m 600 "$template" "$secret" && info "Created $secret"
    fi
done

info "Installing packages from $pkglist..."
sudo pacman -S --needed -- $(< "$pkglist")

ensure_commands stow

info "Stowing dotfiles..."
stow -v -R --no-folding -d "$df_dir" -t "$HOME" core gui

info "Copying /etc files..."
sudo mkdir -p /etc/{iwd,keyd}
sudo cp "$df_dir/etc/iwd/main.conf" "/etc/iwd/main.conf"
sudo cp "$df_dir/etc/keyd/default.conf" "/etc/keyd/default.conf"

if ! command -v zsh &> /dev/null; then
    warn "zsh not found; not changing shell."
elif [[ "$SHELL" != "$(command -v zsh)" ]]; then
    info "Changing shell to zsh..."
    chsh -s "$(command -v zsh)"
fi

info "Enabling Systemd Units..."

systemctl --user daemon-reload
systemctl --user enable zsh-hist-backup.timer
systemctl --user enable crypt-backup.timer
systemctl --user enable crypt-mount.service

sudo systemctl daemon-reload
sudo systemctl enable iwd.service
sudo systemctl enable keyd.service
sudo systemctl enable bluetooth.service
sudo systemctl enable systemd-timesyncd.service
sudo systemctl enable tlp.service

info "Adding user to docker group..."
sudo usermod -aG docker "$USER"

cat <<'EOF'
=========================================================
                  INSTALLATION COMPLETE
=========================================================
  1. Update secrets files:
    - ~/.config/zsh/secrets.zsh
    - ~/.config/gocryptfs/secrets
    - ~/.config/rclone/rclone.conf
  2. Run 'rclone sync crypt:talati-crypt/crypt ~/crypt'
  3. Reboot
=========================================================
EOF
