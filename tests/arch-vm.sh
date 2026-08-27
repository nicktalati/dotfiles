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

    "$dotfiles_dir/scripts/install-vm" --configure-only \
        --account cultivate --account personal >/dev/null
    "$dotfiles_dir/scripts/install-vm" --configure-only >/dev/null

    local neomutt_output
    neomutt_output=$(neomutt \
        -F "$HOME/.config/neomutt/neomuttrc" \
        -Q folder -Q spoolfile -Q from -Q sendmail 2>&1)
    grep -q 'errors in' <<<"$neomutt_output" && fail "NeoMutt configuration did not parse"

    [[ "$(<"$HOME/.config/dotfiles/machine")" == arch-vm ]] || \
        fail "wrong machine marker"
    [[ "$(paste -sd, "$HOME/.config/dotfiles/accounts")" == cultivate,personal ]] || \
        fail "account selection was not persisted"
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

    for account in cultivate personal; do
        [[ -L "$HOME/.config/isync/accounts/$account.conf" ]] || \
            fail "$account native configuration was not Stowed"
        rg -q "\\.local/share/mail/oauth/$account" \
            "$HOME/.config/isync/accounts/$account.conf" || \
            fail "$account does not use the local OAuth path"
    done
    [[ ! -e "$HOME/.config/isync/accounts/paypal.conf" ]] || \
        fail "an unselected account was configured"
    [[ -L "$HOME/.config/systemd/user/mbsync@.service" ]] || \
        fail "per-account mbsync unit was not Stowed"
    [[ -x "$HOME/.local/bin/mail-sync" ]] || fail "mail-sync was not Stowed"
    [[ -L "$HOME/.ssh/id_rsa_personal.pub" ]] || \
        fail "selected personal public key was not Stowed"
    [[ ! -e "$HOME/.ssh/id_rsa_personal" ]] || \
        fail "VM received a private SSH key"
    [[ -d "$HOME/.local/share/mail/oauth" ]] || \
        fail "local OAuth directory was not created"
    [[ ! -e "$HOME/decrypt" && ! -e "$HOME/crypt" ]] || \
        fail "legacy vault directories leaked into the VM"
    rg -q 'ConditionPathExists=%h/.local/share/mail/oauth/%i' \
        "$HOME/.config/systemd/user/mbsync@.service" || \
        fail "mail service does not wait for its local OAuth token"

    if rg -n 'claude-mail|khal|vdirsyncer|quantworks' "$HOME/.config" &>/dev/null; then
        fail "removed mail or calendar configuration leaked into the VM"
    fi

    "$dotfiles_dir/scripts/install-vm" --configure-only --account cultivate >/dev/null
    [[ ! -e "$HOME/.config/isync/accounts/personal.conf" ]] || \
        fail "deselected personal account configuration was not removed"
    [[ ! -L "$HOME/.ssh/id_rsa_personal.pub" ]] || \
        fail "deselected personal public key remained linked"
    [[ "$(<"$HOME/.config/dotfiles/accounts")" == cultivate ]] || \
        fail "replacement account selection was not persisted"
}

test_lima_wrapper() {
    export FAKE_LIMA_LOG="$test_root/lima.log"
    export FAKE_LIMA_CREATED="$test_root/lima.created"
    export FAKE_LIMA_RUNNING="$test_root/lima.running"

    limactl() {
        local command=$1
        shift
        case "$command" in
            list)
                if [[ -f "$FAKE_LIMA_CREATED" ]]; then
                    if [[ "$*" == *Status* ]]; then
                        if [[ -f "$FAKE_LIMA_RUNNING" ]]; then
                            printf 'dev Running\n'
                        else
                            printf 'dev Stopped\n'
                        fi
                    else
                        printf 'dev\n'
                    fi
                fi
                ;;
            create)
                printf 'create %s\n' "$*" >> "$FAKE_LIMA_LOG"
                touch "$FAKE_LIMA_CREATED"
                ;;
            start)
                printf 'start %s\n' "$*" >> "$FAKE_LIMA_LOG"
                touch "$FAKE_LIMA_RUNNING"
                ;;
            shell)
                printf 'shell %s\n' "$*" >> "$FAKE_LIMA_LOG"
                ;;
            *) return 2 ;;
        esac
    }
    export -f limactl

    "$dotfiles_dir/machines/arch-vm/create-lima.sh" >/dev/null
    "$dotfiles_dir/machines/arch-vm/create-lima.sh" >/dev/null

    [[ "$(grep -c '^create ' "$FAKE_LIMA_LOG")" -eq 1 ]] || \
        fail "Lima wrapper recreated an existing VM"
    [[ "$(grep -c '^start ' "$FAKE_LIMA_LOG")" -eq 1 ]] || \
        fail "Lima wrapper restarted an already-running VM"
    grep -q -- '--name dev' "$FAKE_LIMA_LOG" || fail "default instance is not named dev"
    grep -q -- '--mount-none' "$FAKE_LIMA_LOG" || fail "Lima host mounts were not disabled"
    grep -q -- '--containerd none' "$FAKE_LIMA_LOG" || fail "Lima containerd was not disabled"
    grep -q -- '--tty=false' "$FAKE_LIMA_LOG" || fail "Lima creation was interactive"
    grep -q -- 'template:archlinux' "$FAKE_LIMA_LOG" || fail "Arch template was not selected"
}

test_configuration
test_lima_wrapper

printf 'arch-vm smoke test passed\n'
