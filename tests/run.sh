#!/usr/bin/env bash

set -Eeuo pipefail

tests_dir=$(cd "$(dirname "$0")" && pwd)
readonly tests_dir

"$tests_dir/arch-work-guest.sh"
"$tests_dir/fedora-work-guest.sh"
"$tests_dir/mac-work-host.sh"
