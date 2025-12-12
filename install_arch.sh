#!/bin/bash

set -eu

df_conf="$HOME/dotfiles/core/.config"

declare -A secrets_templates=(
    ["$df_conf/zsh/secrets.zsh"]="$df_conf/zsh/secrets.zsh.template"
    ["$df_conf/gocryptfs/secrets"]="$df_conf/gocryptfs/secrets.template"
    ["$df_conf/rclone/rclone.conf"]="$df_conf/rclone/rclone.conf.template"
)

for secret_file in "${!secrets_templates[@]}"; do
    template_file="${secrets_templates[$secret_file]}"
    if [ ! -f "$secret_file" ]; then
        echo "Creating $secret_file..."
        cp "$template_file" "$secret_file"
    fi
done

pkglist="$HOME/dotfiles/pkglist.txt"

if ! command -v paru &> /dev/null; then
    echo "Installing paru-bin..."
    sudo pacman -S --needed base-devel

    mkdir -p /tmp/paru-install
    git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-install

    pushd /tmp/paru-install || exit 1
    makepkg -si --noconfirm
    popd

    rm -rf /tmp/paru-install
else
    echo "Paru is already installed."
fi

if pacman -Qi iptables &>/dev/null && ! pacman -Qi iptables-nft &>/dev/null; then
    echo "Swapping iptables for iptables-nft..."
    yes | sudo pacman -S iptables-nft
fi

echo "Installing packages from $pkglist..."
paru -S --needed --skipreview --noconfirm - < "$pkglist"

mkdir -p "$HOME/.local/state/nvim/undo"
mkdir -p "$HOME/.local/state/python"
mkdir -p "$HOME/.local/state/node"
mkdir -p "$HOME/.local/state/psql"
mkdir -p "$HOME/.local/state/zsh"

echo "Stowing dotfiles..."
stow -v -R --no-folding -d "$HOME/dotfiles" -t "$HOME" core gui

echo "Copying /etc files..."
sudo mkdir -p /etc/iwd /etc/keyd
sudo cp -r "$HOME/dotfiles/etc/iwd/main.conf" /etc/iwd/
sudo cp -r "$HOME/dotfiles/etc/keyd/default.conf" /etc/keyd/

echo "Creating firefox profiles..."
firefox -CreateProfile "personal"
firefox -CreateProfile "work"

if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing shell to zsh..."
    chsh -s "$(which zsh)"
fi

echo "Enabling Systemd Units..."

systemctl --user daemon-reload
systemctl --user enable zsh-hist-backup.timer
systemctl --user enable crypt-backup.timer
systemctl --user enable crypt-mount.service
systemctl --user reset-failed

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
