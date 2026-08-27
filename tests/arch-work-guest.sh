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

    "$dotfiles_dir/install_arch_work_guest.sh" --configure-only >/dev/null
    "$dotfiles_dir/install_arch_work_guest.sh" --configure-only >/dev/null

    local neomutt_output
    neomutt_output=$(neomutt \
        -F "$HOME/.config/neomutt/neomuttrc" \
        -Q folder -Q spoolfile -Q from -Q sendmail 2>&1)
    grep -q 'errors in' <<<"$neomutt_output" && fail "NeoMutt configuration did not parse"

    [[ "$(git config --global user.email)" == talati@getcultivate.ai ]] || \
        fail "wrong work Git email"
    local expected_signing_key
    expected_signing_key=$(git config \
        --file "$dotfiles_dir/work-guest/.config/git/config" \
        user.signingkey)
    [[ "$(git config --global user.signingkey)" == "$expected_signing_key" ]] || \
        fail "wrong work Git signing key"
    [[ "$(notmuch config get database.path)" == "$HOME/mail" ]] || \
        fail "notmuch database path does not follow HOME"
    [[ "$(<"$HOME/.config/dotfiles/machine")" == arch-work-guest ]] || \
        fail "wrong machine marker"
    [[ "$(readlink -f "$HOME/.config/zsh/.zprofile")" == \
        "$dotfiles_dir/work-guest/.config/zsh/.zprofile" ]] || \
        fail "guest zprofile did not override the physical-host profile"
    [[ "$(readlink -f "$HOME/.config/tmux/tmux.conf")" == \
        "$dotfiles_dir/work-guest/.config/tmux/tmux.conf" ]] || \
        fail "guest tmux config did not override the Wayland-host config"

    if rg -n 'XDG_SESSION_TYPE|XDG_CURRENT_DESKTOP|MOZ_ENABLE_WAYLAND' \
        "$HOME/.config/zsh/.zprofile" &>/dev/null; then
        fail "Wayland host environment leaked into guest zprofile"
    fi
    rg -q 'copy-selection-and-cancel' "$HOME/.config/tmux/tmux.conf" || \
        fail "guest tmux clipboard does not use terminal forwarding"
    if rg -q 'copy-pipe.*wl-copy' "$HOME/.config/tmux/tmux.conf"; then
        fail "guest tmux config depends on the physical Wayland clipboard"
    fi

    local goimapnotify_unit="$HOME/.config/systemd/user/goimapnotify@.service"
    [[ -L "$goimapnotify_unit" ]] || fail "goimapnotify user unit was not Stowed"
    rg -q '%h/\.config/goimapnotify/%i\.yaml' "$goimapnotify_unit" || \
        fail "goimapnotify unit points at the wrong config directory"
    [[ -L "$HOME/.config/systemd/user/goimapnotify@work.service.d/work-vault.conf" ]] || \
        fail "goimapnotify is not ordered after the work vault mount"
    [[ -L "$HOME/.config/systemd/user/mbsync.service.d/work-vault.conf" ]] || \
        fail "mbsync is not ordered after the work vault mount"

    if rg -n 'nicktalati@gmail\.com|nicktalatipaypal|quantworks' \
        "$HOME/.config/isyncrc" \
        "$HOME/.config/msmtp/config" \
        "$HOME/.config/goimapnotify" \
        "$HOME/.config/neomutt/neomuttrc" &>/dev/null; then
        fail "non-work mail account leaked into work configuration"
    fi
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
                            printf 'work Running\n'
                        else
                            printf 'work Stopped\n'
                        fi
                    else
                        printf 'work\n'
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
            *)
                return 2
                ;;
        esac
    }
    export -f limactl

    LIMA_INSTANCE=work \
        "$dotfiles_dir/machines/arch-work-guest/create-lima.sh" >/dev/null
    LIMA_INSTANCE=work \
        "$dotfiles_dir/machines/arch-work-guest/create-lima.sh" >/dev/null

    [[ "$(grep -c '^create ' "$FAKE_LIMA_LOG")" -eq 1 ]] || \
        fail "Lima wrapper recreated an existing VM"
    [[ "$(grep -c '^start ' "$FAKE_LIMA_LOG")" -eq 1 ]] || \
        fail "Lima wrapper restarted an already-running VM"
    grep -q -- '--mount-none' "$FAKE_LIMA_LOG" || fail "Lima host mounts were not disabled"
    grep -q -- '--containerd none' "$FAKE_LIMA_LOG" || fail "Lima containerd was not disabled"
    grep -q -- '--tty=false' "$FAKE_LIMA_LOG" || fail "Lima creation was interactive"
    grep -q -- 'template:archlinux' "$FAKE_LIMA_LOG" || fail "Arch template was not selected"
}

test_configuration
test_lima_wrapper

printf 'arch-work-guest smoke test passed\n'
