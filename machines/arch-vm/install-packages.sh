#!/usr/bin/env bash

set -Eeuo pipefail

machine_dir=$(cd "$(dirname "$0")" && pwd)
readonly machine_dir
readonly package_list="$machine_dir/packages.txt"

sudo pacman -Syu --needed --noconfirm base-devel git

if ! command -v yay &>/dev/null; then
    build_dir=$(mktemp -d)
    readonly build_dir
    trap 'rm -rf -- "$build_dir"' EXIT
    git clone --quiet https://aur.archlinux.org/yay-bin.git "$build_dir/yay-bin"
    (
        cd "$build_dir/yay-bin"
        makepkg -si --noconfirm
    )
fi

yay -S --needed --noconfirm - < "$package_list"
