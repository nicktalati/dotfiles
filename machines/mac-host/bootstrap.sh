#!/usr/bin/env bash

set -Eeuo pipefail

readonly dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
readonly brewfile="$dotfiles_dir/machines/mac-host/Brewfile"

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

(($# == 0)) || die "bootstrap.sh takes no arguments"
[[ "$(uname -s)" == Darwin ]] || die "mac-host requires macOS"
[[ "$EUID" -ne 0 ]] || die "do not run this script as root"
[[ -d "$dotfiles_dir/.git" ]] || die "dotfiles repository not found at $dotfiles_dir"
command -v brew &>/dev/null || die "Homebrew is not installed or is not on PATH"

brew bundle install --no-upgrade --file "$brewfile"

stow --restow --no-folding --dir "$dotfiles_dir/stow" --target "$HOME" macos

fdesetup status | grep -q 'FileVault is On' || \
    printf 'warning: FileVault is not enabled\n' >&2

cat <<'EOF'

mac-host bootstrap complete. Create and provision the guest next:

    ~/dotfiles/machines/fedora-vm/create-lima.sh
    limactl shell dev
    ~/dotfiles/machines/fedora-vm/install.sh

Then open a new shell and enter the environment with: dev
EOF
