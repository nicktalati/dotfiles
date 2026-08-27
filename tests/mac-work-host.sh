#!/usr/bin/env bash

set -Eeuo pipefail

dotfiles_dir=$(cd "$(dirname "$0")/.." && pwd)
readonly dotfiles_dir
test_root=$(mktemp -d)
readonly test_root
trap 'rm -rf -- "$test_root"' EXIT

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

home="$test_root/home"
mkdir -p "$home/.local/bin"
stow --restow --no-folding --dir "$dotfiles_dir" --target "$home" mac-host
stow --restow --no-folding --dir "$dotfiles_dir" --target "$home" mac-host

[[ -L "$home/.zprofile" ]] || fail "macOS zprofile was not Stowed"
[[ -L "$home/.local/bin/work" ]] || fail "work launcher was not Stowed"
zsh -n "$home/.zprofile"

export FAKE_LIMA_LOG="$test_root/lima.log"
export FAKE_LIMA_CREATED="$test_root/lima.created"
export FAKE_LIMA_RUNNING="$test_root/lima.running"
export PATH="$dotfiles_dir/tests/fixtures:$PATH"

touch "$FAKE_LIMA_CREATED"
HOME="$home" "$home/.local/bin/work"

[[ "$(grep -c '^start work$' "$FAKE_LIMA_LOG")" -eq 1 ]] || \
    fail "work launcher did not start a stopped VM exactly once"
grep -q '^shell work -- tmux new-session -A -s work$' "$FAKE_LIMA_LOG" || \
    fail "work launcher did not attach to the persistent tmux session"

printf 'mac-work-host smoke test passed\n'
