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

"$dotfiles_dir/machines/fedora-vm/create-lima.sh" >/dev/null
"$dotfiles_dir/machines/fedora-vm/create-lima.sh" >/dev/null

[[ "$(grep -c '^create ' "$FAKE_LIMA_LOG")" -eq 1 ]] || \
    fail "Fedora Lima wrapper recreated an existing VM"
[[ "$(grep -c '^start ' "$FAKE_LIMA_LOG")" -eq 1 ]] || \
    fail "Fedora Lima wrapper restarted an already-running VM"
grep -q -- '--name dev' "$FAKE_LIMA_LOG" || fail "default instance is not named dev"
grep -q -- '--mount-none' "$FAKE_LIMA_LOG" || fail "Lima host mounts were not disabled"
if grep -q 'template:_default/mounts' "$dotfiles_dir/machines/fedora-vm/lima.yaml"; then
    fail "Fedora YAML still inherits a host-home mount"
fi
grep -Eq '^mounts: \[\]$' "$dotfiles_dir/machines/fedora-vm/lima.yaml" || \
    fail "Fedora YAML does not explicitly disable host mounts"
grep -q -- '--containerd none' "$FAKE_LIMA_LOG" || fail "Lima containerd was not disabled"
grep -q -- '--tty=false' "$FAKE_LIMA_LOG" || fail "Lima creation was interactive"
grep -q -- 'fedora-vm/lima.yaml' "$FAKE_LIMA_LOG" || \
    fail "Fedora target did not use its pinned image definition"
grep -q 'forwardAgent: true' "$dotfiles_dir/machines/fedora-vm/lima.yaml" || \
    fail "Fedora VM does not forward the host SSH agent"
if grep -q 'template:archlinux' "$FAKE_LIMA_LOG"; then
    fail "Fedora target fell back to Lima's broken ARM Arch image"
fi
grep -q 'shell dev -- sudo dnf --refresh -y install git' "$FAKE_LIMA_LOG" || \
    fail "Fedora target did not bootstrap Git with DNF"
grep -q 'DOTFILES_REPOSITORY=git@github.com:nicktalati/dotfiles.git' "$FAKE_LIMA_LOG" || \
    fail "Fedora target did not clone through the native forwarded SSH agent"

for package in awscli2 d2 docker-buildx gh neomutt opentofu pandoc-cli \
    sasl-xoauth2 session-manager-plugin uv; do
    grep -Fxq "$package" "$dotfiles_dir/machines/fedora-vm/packages.txt" || \
        fail "Fedora package manifest is missing $package"
done
if rg -n 'khal|vdirsyncer' "$dotfiles_dir/machines/fedora-vm/packages.txt"; then
    fail "removed calendar packages remain in the Fedora manifest"
fi
if rg -n 'gocryptfs|rclone' "$dotfiles_dir/machines/fedora-vm/packages.txt"; then
    fail "legacy vault packages remain in the Fedora VM"
fi

jq --exit-status '.dbmate.version and .fnm.version and ."lua-language-server".version and .goimapnotify.version and ."session-manager-plugin".version' \
    "$dotfiles_dir/machines/fedora-vm/tools.lock.json" >/dev/null
for command_name in dbmate fnm goimapnotify lua-language-server; do
    rg -q "\"$command_name\"|$command_name" "$dotfiles_dir/machines/fedora-vm/install-tools.sh" || \
        fail "Fedora tool installer does not manage $command_name"
done
rg -q 'ln -sfn.*bin_dir' "$dotfiles_dir/machines/fedora-vm/install-tools.sh" || \
    fail "Fedora tool installer does not create stable command links"

yq '.' "$dotfiles_dir/machines/fedora-vm/lima.yaml" >/dev/null
grep -q 'download.fedoraproject.org' "$dotfiles_dir/machines/fedora-vm/lima.yaml" || \
    fail "Fedora image is not sourced from Fedora"
if grep -q 'mcginty/arch-boxes-arm' "$dotfiles_dir/machines/fedora-vm/lima.yaml"; then
    fail "stale third-party Arch ARM image leaked into the Fedora target"
fi

printf 'fedora-vm smoke test passed\n'
