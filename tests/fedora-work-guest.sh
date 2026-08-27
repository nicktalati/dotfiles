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

export FAKE_LIMA_LOG="$test_root/lima.log"
export FAKE_LIMA_CREATED="$test_root/lima.created"
export FAKE_LIMA_RUNNING="$test_root/lima.running"
export PATH="$dotfiles_dir/tests/fixtures:$PATH"

"$dotfiles_dir/machines/fedora-work-guest/create-lima.sh" >/dev/null
"$dotfiles_dir/machines/fedora-work-guest/create-lima.sh" >/dev/null

[[ "$(grep -c '^create ' "$FAKE_LIMA_LOG")" -eq 1 ]] || \
    fail "Fedora Lima wrapper recreated an existing VM"
[[ "$(grep -c '^start ' "$FAKE_LIMA_LOG")" -eq 1 ]] || \
    fail "Fedora Lima wrapper restarted an already-running VM"
grep -q -- '--mount-none' "$FAKE_LIMA_LOG" || fail "Lima host mounts were not disabled"
grep -q -- '--containerd none' "$FAKE_LIMA_LOG" || fail "Lima containerd was not disabled"
grep -q -- '--tty=false' "$FAKE_LIMA_LOG" || fail "Lima creation was interactive"
grep -q -- 'fedora-work-guest/lima.yaml' "$FAKE_LIMA_LOG" || \
    fail "Fedora target did not use its pinned image definition"
if grep -q 'template:archlinux' "$FAKE_LIMA_LOG"; then
    fail "Fedora target fell back to Lima's broken ARM Arch image"
fi
grep -q 'shell work -- sudo dnf --refresh -y install git' "$FAKE_LIMA_LOG" || \
    fail "Fedora target did not bootstrap Git with DNF"

for package in awscli2 d2 docker-buildx gh neomutt opentofu pandoc-cli \
    sasl-xoauth2 session-manager-plugin uv; do
    grep -Fxq "$package" "$dotfiles_dir/machines/fedora-work-guest/packages.txt" || \
        fail "Fedora package manifest is missing $package"
done

home="$test_root/home"
mkdir -p "$home"
stow --restow --no-folding --dir "$dotfiles_dir" --target "$home" fedora-work-guest
for command_name in dbmate fnm goimapnotify lua-language-server; do
    [[ -x "$home/.local/bin/$command_name" ]] || \
        fail "Fedora wrapper is missing or not executable: $command_name"
done

yq '.' "$dotfiles_dir/machines/fedora-work-guest/lima.yaml" >/dev/null
grep -q 'download.fedoraproject.org' "$dotfiles_dir/machines/fedora-work-guest/lima.yaml" || \
    fail "Fedora image is not sourced from Fedora"
if grep -q 'mcginty/arch-boxes-arm' "$dotfiles_dir/machines/fedora-work-guest/lima.yaml"; then
    fail "stale third-party Arch ARM image leaked into the Fedora target"
fi

printf 'fedora-work-guest smoke test passed\n'
