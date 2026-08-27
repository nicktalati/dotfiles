#!/usr/bin/env bash

set -Eeuo pipefail

readonly dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
readonly machine_dir="$dotfiles_dir/machines/mac-host"
readonly brewfile="$machine_dir/Brewfile"

check_only=false

usage() {
    cat <<'EOF'
Usage: bootstrap.sh [--check]

  --check  Verify the declared host packages without changing the machine.
EOF
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

warn() {
    printf 'warning: %s\n' "$*" >&2
}

while (($#)); do
    case "$1" in
        --check)
            check_only=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            die "unknown argument: $1"
            ;;
    esac
    shift
done

[[ "$(uname -s)" == Darwin ]] || die "mac-host requires macOS"
[[ "$EUID" -ne 0 ]] || die "do not run this script as root"
[[ -d "$dotfiles_dir/.git" ]] || die "dotfiles repository not found at $dotfiles_dir"
[[ -f "$brewfile" ]] || die "Brewfile not found at $brewfile"
command -v brew &>/dev/null || die "Homebrew is not installed or is not on PATH"

if $check_only; then
    brew bundle check --file "$brewfile"
    exit
fi

if [[ -e "$HOME/.zprofile" && ! -L "$HOME/.zprofile" ]]; then
    die "$HOME/.zprofile already exists; inspect it before letting mac-host own that path"
fi
if [[ -e "$HOME/.local/bin/dev" && ! -L "$HOME/.local/bin/dev" ]]; then
    die "$HOME/.local/bin/dev already exists; inspect it before Stowing the macOS package"
fi

brew bundle install --no-upgrade --file "$brewfile"

mkdir -p "$HOME/.local/bin"
stow --restow --no-folding --dir "$dotfiles_dir/stow" --target "$HOME" macos

if command -v fdesetup &>/dev/null && ! fdesetup status | grep -q 'FileVault is On'; then
    warn "FileVault is not enabled"
fi

cat <<'EOF'

mac-host bootstrap complete.

This target installed Bitwarden, Lima, Stow, and the `dev` VM launcher. It did
not apply macOS defaults, install development toolchains, or configure launchd
services.

Before creating the VM, enable Bitwarden's SSH agent, import the required keys,
open a new terminal, and verify that `ssh-add -L` lists their public keys.

Create and provision the guest next:

    ~/dotfiles/machines/fedora-vm/create-lima.sh
    limactl shell dev
    ~/dotfiles/scripts/install-vm --account cultivate

After provisioning, open a new host shell and enter the environment with:

    dev
EOF
