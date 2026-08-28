#!/usr/bin/env bash

set -Eeuo pipefail

tests_dir=$(cd "$(dirname "$0")" && pwd)
readonly tests_dir

"$tests_dir/fedora-vm-config.sh"
"$tests_dir/fedora-vm.sh"
"$tests_dir/mac-host.sh"
"$tests_dir/arch-host.sh"
