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
[[ ! -e "$HOME/.config/dotfiles/accounts" ]] || \
    fail "obsolete account-selection state was created"
[[ -L "$HOME/.config/sway/config" ]] || fail "Arch desktop layer was not Stowed"
[[ -L "$HOME/.config/zsh/profile.d/wayland.zsh" ]] || \
    fail "Arch desktop environment fragment was not Stowed"
[[ -L "$HOME/.config/systemd/user/backup.timer" ]] || \
    fail "backup package was not Stowed"
for account in cultivate personal; do
    [[ -L "$HOME/.config/isync/accounts/$account.conf" ]] || \
        fail "$account account package was not Stowed"
done
[[ ! -e "$HOME/.config/neomutt/accounts.rc" ]] || \
    fail "obsolete generated NeoMutt account list was created"
rg -q 'accounts/cultivate.rc' "$HOME/.config/neomutt/neomuttrc" || \
    fail "NeoMutt account composition is missing"
[[ -L "$HOME/.config/notmuch/default/config" ]] || \
    fail "Notmuch configuration was not Stowed"
[[ ! -e "$HOME/.config/systemd/user/mbsync@.service.d/vault.conf" ]] || \
    fail "Arch mail still waits for the legacy vault"
[[ -d "$HOME/.local/share/mail/oauth" ]] || \
    fail "local OAuth directory was not created"
[[ ! -L "$HOME/.local/share/mail/oauth/cultivate" ]] || \
    fail "OAuth token is still a vault symlink"

# Fabricate the Maildirs mbsync (Create Both) creates on first sync; NeoMutt
# reports named-mailboxes whose directories are missing as errors.
while IFS= read -r mailbox; do
    mkdir -p "$HOME/mail/$mailbox"/{cur,new,tmp}
done < <(
    sed -n 's/^named-mailboxes "[^"]*" "+\([^"]*\)"$/\1/p' \
        "$HOME/.config/neomutt/accounts/"*.rc
)

neomutt_output=$(neomutt \
    -F "$HOME/.config/neomutt/neomuttrc" \
    -Q folder -Q spoolfile -Q from -Q sendmail 2>&1)
grep -q 'errors in' <<<"$neomutt_output" && fail "NeoMutt configuration did not parse"

if rg -n 'claude-mail|khal|vdirsyncer|quantworks|nicktalatipaypal' "$HOME/.config" &>/dev/null; then
    fail "removed configuration leaked into the Arch host"
fi

printf 'arch-host smoke test passed\n'
