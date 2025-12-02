#! /bin/bash

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
    echo "Paru is already installed"
fi

mkdir -p "$HOME/.local/state/nvim/undo"
mkdir -p "$HOME/.local/state/python"
mkdir -p "$HOME/.local/state/node"
mkdir -p "$HOME/.local/state/psql"
mkdir -p "$HOME/.local/share/pyenv"

stow -v -R -t "$HOME" core gui

echo "Enabling Systemd Units..."

systemctl --user daemon-reload
systemctl --user enable --now zsh-hist-backup.timer
systemctl --user reset-failed
