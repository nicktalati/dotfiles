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
mkdir -p "$home"
export HOME="$home"
export DOTFILES_DIR="$dotfiles_dir"

"$dotfiles_dir/machines/arch-host/install.sh" --configure-only >/dev/null
"$dotfiles_dir/machines/arch-host/install.sh" --configure-only >/dev/null

[[ "$(<"$HOME/.config/dotfiles/machine")" == arch-host ]] || \
    fail "wrong Arch host marker"
[[ "$(paste -sd, "$HOME/.config/dotfiles/accounts")" == cultivate,personal,paypal ]] || \
    fail "Arch host did not select all accounts"
[[ -L "$HOME/.config/sway/config" ]] || fail "Arch desktop layer was not Stowed"
[[ -L "$HOME/.config/zsh/profile.d/wayland.zsh" ]] || \
    fail "Arch desktop environment fragment was not Stowed"
[[ -L "$HOME/.config/systemd/user/crypt-backup.timer" ]] || \
    fail "Arch backup package was not Stowed"
for account in cultivate personal paypal; do
    [[ -L "$HOME/.config/isync/accounts/$account.conf" ]] || \
        fail "$account account package was not Stowed"
done
[[ -L "$HOME/.config/systemd/user/mbsync@.service.d/vault.conf" ]] || \
    fail "Arch mail does not wait for the legacy vault"
[[ -L "$HOME/.local/share/mail/oauth/cultivate" ]] || \
    fail "Arch OAuth compatibility link was not created"

neomutt_output=$(neomutt \
    -F "$HOME/.config/neomutt/neomuttrc" \
    -Q folder -Q spoolfile -Q from -Q sendmail 2>&1)
grep -q 'errors in' <<<"$neomutt_output" && fail "NeoMutt configuration did not parse"

if rg -n 'claude-mail|khal|vdirsyncer|quantworks' "$HOME/.config" &>/dev/null; then
    fail "removed configuration leaked into the Arch host"
fi

printf 'arch-host smoke test passed\n'
