#!/usr/bin/env bash

set -Eeuo pipefail

readonly dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
readonly machine_dir="$dotfiles_dir/machines/mac-work-host"
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

[[ "$(uname -s)" == Darwin ]] || die "mac-work-host requires macOS"
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
if [[ -e "$HOME/.local/bin/work" && ! -L "$HOME/.local/bin/work" ]]; then
    die "$HOME/.local/bin/work already exists; inspect it before Stowing mac-host"
fi

brew bundle install --no-upgrade --file "$brewfile"

mkdir -p "$HOME/.local/bin"
stow --restow --no-folding --dir "$dotfiles_dir" --target "$HOME" mac-host

if command -v fdesetup &>/dev/null && ! fdesetup status | grep -q 'FileVault is On'; then
    warn "FileVault is not enabled"
fi

cat <<'EOF'

mac-work-host bootstrap complete.

This target installed only Lima, Stow, Firefox, and the `work` VM launcher. It
did not apply macOS defaults, install development toolchains, or configure
launchd services.

Create and provision the guest next:

    ~/dotfiles/machines/fedora-work-guest/create-lima.sh
    limactl shell work
    ~/dotfiles/install_work_guest.sh

After provisioning, open a new host shell and enter the environment with:

    work
EOF
