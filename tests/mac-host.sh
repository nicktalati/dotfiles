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
stow --restow --no-folding --dir "$dotfiles_dir/stow" --target "$home" macos wallpaper
stow --restow --no-folding --dir "$dotfiles_dir/stow" --target "$home" macos wallpaper

[[ -L "$home/.zprofile" ]] || fail "macOS zprofile was not Stowed"
[[ -L "$home/.local/bin/dev" ]] || fail "dev launcher was not Stowed"
[[ -L "$home/.ssh/config" ]] || fail "macOS SSH config was not Stowed"
zsh -n "$home/.zprofile"
if rg -n 'firefox' "$dotfiles_dir/machines/mac-host/Brewfile"; then
    fail "Mac host still installs Firefox even though Safari is the selected browser"
fi
grep -q 'cask "bitwarden"' "$dotfiles_dir/machines/mac-host/Brewfile" || \
    fail "Mac host does not install Bitwarden"
if rg -n 'bitwarden.*ssh-agent|bitwarden-ssh-agent' "$home/.zprofile"; then
    fail "Mac host still uses Bitwarden for SSH"
fi
grep -q 'UseKeychain yes' "$home/.ssh/config" || \
    fail "Mac host does not use the native Keychain-backed SSH agent"
grep -q 'apple-load-keychain' "$home/.zprofile" || \
    fail "Mac host does not populate the agent from Keychain at login"

grep -q 'cask "ghostty"' "$dotfiles_dir/machines/mac-host/Brewfile" || \
    fail "Mac host does not install the terminal the VM is seen through"
[[ -L "$home/.config/ghostty/config" ]] || fail "Ghostty configuration was not Stowed"
grep -q '^macos-option-as-alt = true$' "$home/.config/ghostty/config" || \
    fail "Ghostty would compose Option instead of sending tmux its Alt bindings"
grep -q '^window-padding-color = extend$' "$home/.config/ghostty/config" || \
    fail "Ghostty would frame Neovim in the window background colour"
grep -q '^clipboard-write = allow$' "$home/.config/ghostty/config" || \
    fail "Ghostty would refuse the OSC 52 clipboard path out of the VM"

ghostty_image=$(sed -n 's/^background-image = ~\///p' "$home/.config/ghostty/config")
[[ -n "$ghostty_image" ]] || fail "Ghostty has no background image"
[[ -f "$home/$ghostty_image" ]] || \
    fail "Ghostty's background image is not Stowed at the path it names"
if grep -qE '^background-(opacity|blur) =' "$home/.config/ghostty/config"; then
    fail "window transparency would scale the background image back down"
fi
grep -q 'wallpapers/ocean.png' "$dotfiles_dir/stow/arch-desktop/.config/sway/config" || \
    fail "Sway and Ghostty no longer draw the same wallpaper"

export FAKE_LIMA_LOG="$test_root/lima.log"
export FAKE_LIMA_CREATED="$test_root/lima.created"
export FAKE_LIMA_RUNNING="$test_root/lima.running"
export PATH="$dotfiles_dir/tests/fixtures:$PATH"

touch "$FAKE_LIMA_CREATED"
HOME="$home" "$home/.local/bin/dev"

[[ "$(grep -c '^start dev$' "$FAKE_LIMA_LOG")" -eq 1 ]] || \
    fail "dev launcher did not start a stopped VM exactly once"
grep -q '^shell dev -- tmux new-session -A -s dev$' "$FAKE_LIMA_LOG" || \
    fail "dev launcher did not attach to the persistent tmux session"

printf 'mac-host smoke test passed\n'
