#! /bin/bash

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
