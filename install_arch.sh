#!/bin/bash
set -Eeuo pipefail
exec > >(tee -i "$(date +%Y%m%d.%H-%M-%S).log") 2>&1

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

ensure_dir() { [[ -d "$1" ]] || error "Directory does not exist: $1"; }
ensure_file() { [[ -f "$1" ]] || error "File does not exist: $1"; }
ensure_commands() {
    for cmd in "$@"; do
        command -v "$cmd" &> /dev/null || error "Command is not available: $cmd"
    done
}

cp_template() {
    local src="$1" dest="$2"
    [[ -f "$src" ]] || error "Template missing: $src"
    [[ -f "$dest" ]] && { warn "Secret exists: $dest Skipping..."; return 0; }
    install -m 600 "$src" "$dest" && info "Created $dest"
}

grep -iqs "ID=arch" "/etc/os-release" || error "System is not Arch."
sudo -v || error "This script required sudo privileges"
ensure_commands pacman sudo git
ensure_dir "$df_dir"
ensure_dir "$df_conf"
ensure_file "$pkglist"

mkdir -p "$xdg_state"/{nvim/undo,python,node,psql,zsh}

for secret in "${!secrets_templates[@]}"; do
    template="${secrets_templates[$secret]}"
    cp_template "$template" "$secret"
done

if ! command -v paru &> /dev/null; then
    info "Installing paru..."
    sudo pacman -S --needed --noconfirm base-devel

    temp_dir=""
    trap '[ -n "$temp_dir" ] && rm -rf "$temp_dir"' EXIT
    temp_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru.git "$temp_dir"

    pushd "$temp_dir"
    makepkg -si --noconfirm
    popd

    ensure_commands paru
else
    info "Paru is already installed."
fi

info "Installing packages from $pkglist..."
paru -S --needed --noconfirm -- $(< "$pkglist")

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
sudo systemctl enable iwd
sudo systemctl enable keyd.service
sudo systemctl enable bluetooth.service
sudo systemctl enable systemd-timesyncd.service

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
