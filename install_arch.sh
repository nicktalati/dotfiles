#!/bin/bash

ZSH_SECRETS_FILE="$HOME/dotfiles/core/.config/zsh/secrets.zsh"
ZSH_TEMPLATE_FILE="$HOME/dotfiles/core/.config/zsh/secrets.zsh.template"
CRYPT_SECRETS_FILE="$HOME/dotfiles/core/.config/cryptomator/secrets"
CRYPT_TEMPLATE_FILE="$HOME/dotfiles/core/.config/cryptomator/secrets.template"
PKGLIST="$HOME/dotfiles/pkglist.txt"

if [ ! -f "$ZSH_SECRETS_FILE" ]; then
    echo "WARNING: zsh secrets file not found."
    echo "Creating empty secrets file from template..."
    cp "$ZSH_TEMPLATE_FILE" "$ZSH_SECRETS_FILE"
    chmod 600 "$ZSH_SECRETS_FILE"
    echo "Please edit $ZSH_SECRETS_FILE."
fi

if [ ! -f "$CRYPT_SECRETS_FILE" ]; then
    echo "WARNING: Cryptomator secrets file not found."
    echo "Creating empty secrets file from template..."
    cp "$CRYPT_TEMPLATE_FILE" "$CRYPT_SECRETS_FILE"
    chmod 600 "$CRYPT_SECRETS_FILE"
    echo "Please edit $CRYPT_SECRETS_FILE and then retry installation."
    exit 1
fi

if ! command -v paru &> /dev/null; then
    echo "Installing paru..."
    sudo pacman -S --needed base-devel

    mkdir -p /tmp/paru-install
    git clone https://aur.archlinux.org/paru.git /tmp/paru-install

    pushd /tmp/paru-install || exit 1
    makepkg -si --noconfirm
    popd

    rm -rf /tmp/paru-install
else
    echo "Paru is already installed."
fi

echo "Installing packages from $PKGLIST..."
paru -S --needed --skipreview - < "$PKGLIST"

mkdir -p "$HOME/.local/state/nvim/undo"
mkdir -p "$HOME/.local/state/python"
mkdir -p "$HOME/.local/state/node"
mkdir -p "$HOME/.local/state/psql"
mkdir -p "$HOME/.local/share/pyenv"

stow -v -R -t "$HOME" core gui

echo "Enabling Systemd Units..."

systemctl --user daemon-reload
systemctl --user enable --now zsh-hist-backup.timer
systemctl --user enable --now cryptomator.service
systemctl --user reset-failed
