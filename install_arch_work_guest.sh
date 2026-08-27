#!/usr/bin/env bash

set -Eeuo pipefail

dotfiles_dir=$(cd "$(dirname "$0")" && pwd)
readonly dotfiles_dir

exec "$dotfiles_dir/install_work_guest.sh" "$@"
