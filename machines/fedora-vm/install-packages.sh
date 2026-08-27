#!/usr/bin/env bash

set -Eeuo pipefail

machine_dir=$(cd "$(dirname "$0")" && pwd)
readonly machine_dir
readonly package_list="$machine_dir/packages.txt"
readonly external_package=session-manager-plugin

mapfile -t packages < <(grep -Fvx "$external_package" "$package_list")

sudo dnf --refresh -y upgrade
sudo dnf -y install "${packages[@]}"
"$machine_dir/install-tools.sh"
