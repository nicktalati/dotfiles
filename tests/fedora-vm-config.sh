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

test_configuration() {
    local home="$test_root/home"
    mkdir -p "$home"

    export HOME="$home"
    export DOTFILES_DIR="$dotfiles_dir"
    export XDG_CONFIG_HOME="$home/.config"
    export XDG_STATE_HOME="$home/.local/state"

    # The installer needs dnf, sudo, and systemd, so it cannot run here.
    # Recreate the home it produces: the fedora-vm Stow composition plus the
    # machine marker pkgsync reads.
    stow --restow --no-folding --dir "$dotfiles_dir/stow" --target "$HOME" \
        shell nvim tmux git mail psql task backup \
        account-cultivate account-personal
    mkdir -p "$XDG_CONFIG_HOME/dotfiles"
    printf '%s\n' fedora-vm > "$XDG_CONFIG_HOME/dotfiles/machine"

    # Fabricate the Maildirs mbsync (Create Both) creates on first sync;
    # NeoMutt reports named-mailboxes whose directories are missing as errors.
    local mailbox
    while IFS= read -r mailbox; do
        mkdir -p "$HOME/mail/$mailbox"/{cur,new,tmp}
    done < <(
        sed -n 's/^named-mailboxes "[^"]*" "+\([^"]*\)"$/\1/p' \
            "$XDG_CONFIG_HOME/neomutt/accounts/"*.rc
    )

    local neomutt_output
    neomutt_output=$(neomutt \
        -F "$HOME/.config/neomutt/neomuttrc" \
        -Q folder -Q spoolfile -Q from -Q sendmail 2>&1)
    grep -q 'errors in' <<<"$neomutt_output" && fail "NeoMutt configuration did not parse"

    # -Q never fires folder-hooks; opening the spoolfile does, which is how
    # the sendmail metacharacter regression surfaced.
    TERM=xterm-256color timeout 15 script -qec \
        "neomutt -F '$HOME/.config/neomutt/neomuttrc' -e 'push <quit>'" /dev/null \
        </dev/null &>"$test_root/neomutt-open.log" || \
        fail "NeoMutt did not open the spoolfile and quit cleanly"
    if grep -aq 'metacharacters\|Error in' "$test_root/neomutt-open.log"; then
        fail "opening the spoolfile produced NeoMutt errors"
    fi

    [[ "$(notmuch config get database.path)" == "$HOME/mail" ]] || \
        fail "notmuch database path does not follow HOME"
    [[ "$(notmuch config get user.primary_email)" == talati@getcultivate.ai ]] || \
        fail "notmuch primary account is wrong"

    mkdir -p "$HOME/dotfiles" "$HOME/code/legacy-personal" \
        "$HOME/code/cultivate/example" "$HOME/code/personal/example"
    git -C "$HOME/dotfiles" init -q
    git -C "$HOME/code/legacy-personal" init -q
    git -C "$HOME/code/cultivate/example" init -q
    git -C "$HOME/code/personal/example" init -q
    [[ "$(git -C "$HOME/dotfiles" config user.email)" == nicktalati@gmail.com ]] || \
        fail "dotfiles repository did not select the personal Git identity"
    [[ "$(git -C "$HOME/code/legacy-personal" config user.email)" == nicktalati@gmail.com ]] || \
        fail "legacy personal repository did not select the personal Git identity"
    [[ "$(git -C "$HOME/code/cultivate/example" config user.email)" == talati@getcultivate.ai ]] || \
        fail "Cultivate repository did not select the Cultivate Git identity"
    [[ "$(git -C "$HOME/code/personal/example" config user.email)" == nicktalati@gmail.com ]] || \
        fail "personal repository did not select the personal Git identity"
    [[ "$(readlink -f "$HOME/.config/zsh/.zprofile")" == \
        "$dotfiles_dir/stow/shell/.config/zsh/.zprofile" ]] || \
        fail "VM did not use the shared Zsh profile"
    [[ "$(readlink -f "$HOME/.config/tmux/tmux.conf")" == \
        "$dotfiles_dir/stow/tmux/.config/tmux/tmux.conf" ]] || \
        fail "VM did not use the shared tmux config"

    if rg -n 'XDG_SESSION_TYPE|XDG_CURRENT_DESKTOP|MOZ_ENABLE_WAYLAND' \
        "$HOME/.config/zsh/.zprofile" &>/dev/null; then
        fail "Wayland host environment leaked into VM zprofile"
    fi
    rg -q "command -v wl-copy" "$HOME/.config/tmux/tmux.conf" || \
        fail "shared tmux config does not detect the available clipboard"
    rg -q 'copy-selection-and-cancel' "$HOME/.config/tmux/tmux.conf" || \
        fail "shared tmux config has no OSC 52 fallback"
    rg -q 'copy-pipe.*wl-copy' "$HOME/.config/tmux/tmux.conf" || \
        fail "shared tmux config has no Wayland clipboard path"

    [[ ! -e "$HOME/.config/neomutt/accounts.rc" ]] || \
        fail "obsolete generated NeoMutt account list was created"
    rg -q 'accounts/cultivate.rc' "$HOME/.config/neomutt/neomuttrc" || \
        fail "NeoMutt account composition is missing"
    [[ "$(readlink -f "$HOME/.config/notmuch/default/config")" == \
        "$dotfiles_dir/stow/mail/.config/notmuch/default/config" ]] || \
        fail "Notmuch configuration was generated instead of Stowed"

    for account in cultivate personal; do
        [[ -L "$HOME/.config/isync/accounts/$account.conf" ]] || \
            fail "$account native configuration was not Stowed"
        rg -q "\\.local/share/mail/oauth/$account" \
            "$HOME/.config/isync/accounts/$account.conf" || \
            fail "$account does not use the local OAuth path"
    done
    [[ -L "$HOME/.config/systemd/user/mbsync@.service" ]] || \
        fail "per-account mbsync unit was not Stowed"
    [[ -x "$HOME/.local/bin/mail-sync" ]] || fail "mail-sync was not Stowed"
    [[ -x "$HOME/.local/bin/mail-enroll" ]] || fail "mail-enroll was not Stowed"
    [[ -x "$HOME/.local/bin/backup" ]] || fail "backup was not Stowed"
    rg -q 'ConditionPathExists=%h/.config/restic/env' \
        "$HOME/.config/systemd/user/backup.service" || \
        fail "backup service does not gate on restic credentials"
    [[ -x "$HOME/.local/bin/pkgsync" ]] || fail "pkgsync was not Stowed"
    [[ "$("$HOME/.local/bin/pkgsync" path)" == \
        "$dotfiles_dir/machines/fedora-vm/packages.txt" ]] || \
        fail "pkgsync did not select the Fedora manifest"
    if compgen -G "$HOME/.ssh/id_*" >/dev/null; then
        fail "SSH key material leaked into the Stow packages"
    fi
    [[ ! -e "$HOME/decrypt" && ! -e "$HOME/crypt" ]] || \
        fail "legacy vault directories leaked into the VM"
    rg -q 'ConditionPathExists=%h/.local/share/mail/oauth/%i' \
        "$HOME/.config/systemd/user/mbsync@.service" || \
        fail "mail service does not wait for its local OAuth token"

    if rg -n 'claude-mail|khal|vdirsyncer|quantworks|nicktalatipaypal' "$HOME/.config" &>/dev/null; then
        fail "removed mail or calendar configuration leaked into the VM"
    fi
}

test_configuration

printf 'fedora-vm configuration smoke test passed\n'
