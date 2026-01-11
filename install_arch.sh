#!/bin/bash
# TODO: define vars in .zprofile and source here?

set -Eeuo pipefail
exec > >(tee -i "/tmp/install-$(date +%Y%m%d.%H-%M-%S).log") 2>&1

# TODO: some of the vars in question...
readonly df_dir="$HOME/dotfiles"
readonly df_conf="$df_dir/core/.config"
readonly pkglist="$df_dir/pkglist.txt"

readonly decrypt_dir="$HOME/decrypt"
readonly decrypt_secrets="$decrypt_dir/secrets"

readonly xdg_state="$HOME/.local/state"
readonly xdg_conf="$HOME/.config"

readonly rclone_tmpl="$df_conf/rclone/rclone.conf.template"
readonly rclone_conf="$xdg_conf/rclone/rclone.conf"
readonly gcfs_conf="$xdg_conf/gocryptfs/secrets"

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

# checks
[[ "$EUID" -ne 0 ]] || error "Script must not be run as root."
ensure_commands pacman sudo
grep -iqs "ID=arch" "/etc/os-release" || error "System is not Arch."

[[ -d "$df_dir" ]] || error "Directory does not exist: $df_dir"
[[ -d "$df_conf" ]] || error "Directory does not exist: $df_conf"
[[ -f "$pkglist" ]] || error "File does not exist: $pkglist"

sudo -v || error "This script required sudo privileges."

# sudo loop so no reauth TODO: chsh still asks
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done &>/dev/null &

# general dirs TODO: is this the right place
mkdir -p "$xdg_state"/{nvim/undo,python,node,psql,zsh,msmtp}
mkdir -p "$HOME/Downloads"

# email dir setup for neomutt
readonly email_accounts=(
    "nicktalati"
    "nicktalatipaypal"
    "quantworks"
)

for account in "${email_accounts[@]}"; do
    mkdir -p "$HOME/mail/$account"
    mkdir -p "$HOME/mail/.header-$account"/{cur,new,tmp}
done

# pkg install
info "Installing packages from $pkglist..."
sudo pacman -S --needed -- $(< "$pkglist")

# stow
ensure_commands stow

info "Stowing dotfiles..."
stow -v -R --no-folding -d "$df_dir" -t "$HOME" core email gui

# secrets
info "Setting up secrets..."
mkdir -p "$xdg_conf"/{rclone,gocryptfs}
mkdir -p "$HOME/.ssh/config.d"
if [[ ! -f "$gcfs_conf" ]]; then
    echo -n "Gocryptfs password: "
    read -s gcfs_pass
    echo
    echo "$gcfs_pass" > "$gcfs_conf"
    chmod 600 "$gcfs_conf"
fi

[[ -f "$rclone_tmpl" ]] || error "Template missing: $rclone_tmpl"
[[ -f "$rclone_conf" ]] || install -m 600 "$rclone_tmpl" "$rclone_conf"

# link broken until decrypt mounted by gocryptfs
ln -sf "$decrypt_secrets/secrets.zsh" "$xdg_conf/zsh/secrets.zsh"

ssh_keys=(
    "config.d/work"
    "greenville.pem"
    "id_rsa_personal"
    "id_rsa_personal.pub"
    "id_rsa_work_github"
    "id_rsa_work_github.pub"
    "id_rsa_work_gitlab"
    "id_rsa_work_gitlab.pub"
)

# links broken until decrypt mounted by gocryptfs
for key in "${ssh_keys[@]}"; do
    ln -sf "$decrypt_secrets/ssh/$key" "$HOME/.ssh/$key"
done

info "Copying /etc files..."
sudo mkdir -p /etc/{iwd,keyd}
sudo cp "$df_dir/etc/iwd/main.conf" "/etc/iwd/main.conf"
sudo cp "$df_dir/etc/keyd/default.conf" "/etc/keyd/default.conf"

# change shell
# TODO: do i need the check? probably smart
if ! command -v zsh &> /dev/null; then
    warn "zsh not found; not changing shell."
elif [[ "$SHELL" != "$(command -v zsh)" ]]; then
    info "Changing shell to zsh..."
    chsh -s "$(command -v zsh)"
fi

# systemd units
# TODO: verify these are the essential ones
# TODO: should i check first? currently takes a bit
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

# docker
# TODO: seems misplaced, and do i need docker?
info "Adding user to docker group..."
sudo usermod -aG docker "$USER"

cat <<'EOF'
=========================================================
                  INSTALLATION COMPLETE
=========================================================
  1. Update ~/.config/rclone/rclone.conf
  2. Run 'rclone sync crypt:talati-crypt/crypt ~/crypt'
  3. Reboot
=========================================================
EOF
