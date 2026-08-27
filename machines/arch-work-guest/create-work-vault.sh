#!/usr/bin/env bash

set -Eeuo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
readonly script_dir

exec "$script_dir/../work-guest/create-work-vault.sh" "$@"
