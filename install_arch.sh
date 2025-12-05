#!/bin/bash

ZSH_SECRETS_FILE="$HOME/dotfiles/core/.config/zsh/secrets.zsh"
ZSH_TEMPLATE_FILE="$HOME/dotfiles/core/.config/zsh/secrets.zsh.template"
CRYPT_SECRETS_FILE="$HOME/dotfiles/core/.config/gocryptfs/secrets"
CRYPT_TEMPLATE_FILE="$HOME/dotfiles/core/.config/gocryptfs/secrets.template"
PKGLIST="$HOME/dotfiles/pkglist.txt"

if [ ! -f "$ZSH_SECRETS_FILE" ]; then
    echo "WARNING: zsh secrets file not found."
    echo "Creating empty secrets file from template..."
    cp "$ZSH_TEMPLATE_FILE" "$ZSH_SECRETS_FILE"
    chmod 600 "$ZSH_SECRETS_FILE"
    echo "Please edit $ZSH_SECRETS_FILE."
fi

if [ ! -f "$CRYPT_SECRETS_FILE" ]; then
    echo "WARNING: Gocryptfs secrets file not found."
    echo "Creating empty secrets file from template..."
    cp "$CRYPT_TEMPLATE_FILE" "$CRYPT_SECRETS_FILE"
    chmod 600 "$CRYPT_SECRETS_FILE"
    echo "Please edit $CRYPT_SECRETS_FILE and then retry installation."
    exit 1
fi

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
    echo "Swapping legacy iptables for iptables-nft..."
    yes | sudo pacman -S iptables-nft
fi

echo "Installing packages from $PKGLIST..."
paru -S --needed --skipreview --noconfirm - < "$PKGLIST"

mkdir -p "$HOME/.local/state/nvim/undo"
mkdir -p "$HOME/.local/state/python"
mkdir -p "$HOME/.local/state/node"
mkdir -p "$HOME/.local/state/psql"
mkdir -p "$HOME/.local/state/zsh"
mkdir -p "$HOME/.local/share/pyenv"
mkdir -p "$HOME/.config/systemd/user"

stow -v -R -t "$HOME" core gui

if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing shell to zsh..."
    chsh -s "$(which zsh)"
fi

echo "Enabling Systemd Units..."

systemctl --user daemon-reload
systemctl --user enable --now zsh-hist-backup.timer
systemctl --user enable vault-mount.service
systemctl --user reset-failed

echo ""
echo "======================================================="
echo "                 INSTALLATION COMPLETE                 "
echo "======================================================="
echo "  1. Log out and log back in                           "
echo "  2. Run '/usr/bin/dropbox' and sign in                "
echo "  3. Ctl+C to stop after sync                          "
echo "  3. Run 'gocryptfs -init ~/Dropbox/crypt'             "
echo "  4. Run 'systemctl --user start vault-mount.service'  "
echo "======================================================="
