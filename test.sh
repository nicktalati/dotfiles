#!/usr/bin/env bash
# Every check runs something and looks at the result; nothing asserts what a
# configuration file says. Runs on either Linux host.

set -Eeuo pipefail

dotfiles=$(cd "$(dirname "$0")" && pwd)
readonly dotfiles
root=$(mktemp -d)
readonly root
trap 'rm -rf -- "$root"' EXIT

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

# Render a machine's home the way its installer does, into an empty directory.
configure() {
    export HOME="$root/$1"
    export XDG_CONFIG_HOME="$HOME/.config" XDG_STATE_HOME="$HOME/.local/state"
    mkdir -p "$HOME"
    "$dotfiles/machines/$1/install.sh" --configure-only &>"$root/$1.log" || {
        cat "$root/$1.log" >&2
        fail "$1 installer failed in --configure-only mode"
    }
}

# -Q never fires folder-hooks; opening the spoolfile does. NeoMutt reports
# named-mailboxes whose Maildirs are missing as errors, so create them first.
check_neomutt() {
    local mailbox
    while IFS= read -r mailbox; do
        mkdir -p "$HOME/mail/$mailbox"/{cur,new,tmp}
    done < <(sed -n 's/^named-mailboxes "[^"]*" "+\([^"]*\)"$/\1/p' \
        "$XDG_CONFIG_HOME/neomutt/accounts/"*.rc)
    TERM=xterm-256color timeout 15 script -qec \
        "neomutt -F '$XDG_CONFIG_HOME/neomutt/neomuttrc' -e 'push <quit>'" /dev/null \
        </dev/null &>"$root/neomutt.log" || \
        fail "NeoMutt did not open the spoolfile and quit cleanly"
    if grep -aqE 'metacharacters|Error in|errors in' "$root/neomutt.log"; then
        fail "NeoMutt reported: $(grep -aE 'metacharacters|Error in|errors in' "$root/neomutt.log" | head -3)"
    fi
}

# A fake limactl that logs create/start/shell calls and remembers whether the
# instance exists and is running, in files next to itself.
mkdir -p "$root/lima"
cat > "$root/lima/limactl" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
state=$(dirname "$0")
case "$1" in
    list)
        [[ -f "$state/created" ]] || exit 0
        status=Stopped
        [[ -f "$state/running" ]] && status=Running
        if [[ "$*" == *Status* ]]; then
            printf 'dev %s\n' "$status"
        else
            printf 'dev\n'
        fi
        ;;
    create) printf '%s\n' "$*" >> "$state/log"; touch "$state/created" ;;
    start) printf '%s\n' "$*" >> "$state/log"; touch "$state/running" ;;
    shell) printf '%s\n' "$*" >> "$state/log" ;;
    *) exit 2 ;;
esac
FAKE
chmod +x "$root/lima/limactl"
export PATH="$root/lima:$PATH"
export DOTFILES_DIR="$dotfiles"

shellcheck -S warning "$dotfiles"/machines/*/*.sh \
    "$dotfiles"/machines/arch-host/firefox/setup.sh \
    "$dotfiles"/machines/fedora-vm/lua-language-server \
    "$dotfiles"/stow/*/.local/bin/* "$dotfiles/test.sh" "$root/lima/limactl"

# fedora-vm
mkdir -p "$root/fedora-vm"
printf '# skel\n' > "$root/fedora-vm/.bash_profile"
configure fedora-vm
[[ -L "$HOME/.bash_profile" ]] || fail "installer did not replace Fedora's skel .bash_profile"
check_neomutt
[[ "$(zsh -l -c 'print -r -- "$BROWSER"')" == echo ]] || \
    fail "a VM login shell would open URLs in lynx"

mkdir -p "$HOME/dotfiles" "$HOME/work/repo" "$HOME/code/repo"
for repo in dotfiles work/repo code/repo; do
    git -C "$HOME/$repo" init -q
done
[[ "$(git -C "$HOME/work/repo" config user.email)" == talati@getcultivate.ai ]] || \
    fail "a repository under ~/work did not get the Cultivate identity"
[[ "$(git -C "$HOME/code/repo" config user.email)" == nicktalati@gmail.com && \
    "$(git -C "$HOME/dotfiles" config user.email)" == nicktalati@gmail.com ]] || \
    fail "repositories under code/ and dotfiles/ did not get the personal identity"

# mbsync creates mailboxes but not the Maildir store that holds them.
mkdir -p "$root/stubs" "$HOME/.local/share/mail/oauth"
printf '#!/bin/sh\nexit 0\n' | tee "$root/stubs/mbsync" > "$root/stubs/notmuch"
chmod +x "$root/stubs"/*
: > "$HOME/.local/share/mail/oauth/personal"
PATH="$root/stubs:$PATH" "$HOME/.local/bin/mail-sync" personal >/dev/null
[[ -d "$HOME/mail/nicktalati" ]] || fail "mail-sync did not create the Maildir store"

# Network errors exit 75, which mbsync@.service counts as success; anything
# else fails the unit.
mail_sync_status() {
    printf '#!/bin/sh\necho "%s" >&2\nexit 1\n' "$1" > "$root/stubs/mbsync"
    local status=0
    PATH="$root/stubs:$PATH" "$HOME/.local/bin/mail-sync" personal &>/dev/null || status=$?
    printf '%s\n' "$status"
}
[[ "$(mail_sync_status 'Socket error on imap.gmail.com (1.2.3.4:993): timeout.')" == 75 ]] || \
    fail "mail-sync failed the unit on a socket timeout"
[[ "$(mail_sync_status 'Skipping account personal, PassCmd exited with status 1')" == 1 ]] || \
    fail "mail-sync treated a failing PassCmd as transient"

# notify-failure goes through the headless notify-send to the journal, which
# vm-notify reads on the Mac (below).
printf '#!/bin/sh\necho "Synchronize mail account cultivate"\n' > "$root/stubs/systemctl"
cat > "$root/stubs/logger" <<'STUB'
#!/bin/sh
for line; do :; done
printf '%s\n' "$line" >> "$(dirname "$0")/journal"
STUB
chmod +x "$root/stubs"/*
for _ in 1 2; do
    PATH="$HOME/.local/bin:$root/stubs:$PATH" "$HOME/.local/bin/notify-failure" mbsync@cultivate
done

[[ "$("$HOME/.local/bin/pkgsync" path)" == "$dotfiles/machines/fedora-vm/packages.txt" ]] || \
    fail "pkgsync did not select the Fedora manifest"

"$dotfiles/machines/fedora-vm/create-lima.sh" >/dev/null
"$dotfiles/machines/fedora-vm/create-lima.sh" >/dev/null
[[ "$(grep -c '^create ' "$root/lima/log")" == 1 && "$(grep -c '^start ' "$root/lima/log")" == 1 ]] || \
    fail "create-lima.sh recreated or restarted an existing VM"

# arch-host
configure arch-host
check_neomutt

# mac-host
export HOME="$root/mac-host" XDG_CONFIG_HOME="$root/mac-host/.config"
mkdir -p "$HOME"
stow --restow --no-folding --dir "$dotfiles/stow" --target "$HOME" macos wallpaper
zsh -n "$HOME/.zprofile" || fail "macOS .zprofile does not parse"
python3 -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' \
    "$HOME/.config/aerospace/aerospace.toml" || fail "AeroSpace config is not valid TOML"
rm -f "$root/lima/running"
: > "$root/lima/log"
"$HOME/.local/bin/dev"
grep -q '^start dev$' "$root/lima/log" || fail "dev did not start the stopped VM"
grep -q '^shell dev -- tmux new-session -A -s dev$' "$root/lima/log" || \
    fail "dev did not attach to the tmux session"

printf '#!/bin/sh\ncat "$(dirname "$0")/journal"\n' > "$root/stubs/ssh"
cat > "$root/stubs/osascript" <<'STUB'
#!/usr/bin/env bash
printf '%s|' "${@: -2}" >> "$(dirname "$0")/shown"
STUB
chmod +x "$root/stubs"/*
PATH="$root/stubs:$PATH" "$HOME/.local/bin/vm-notify"
[[ "$(cat "$root/stubs/shown")" == 'mbsync@cultivate failed|Synchronize mail account cultivate|' ]] || \
    fail "a failed unit did not reach the Mac as exactly one notification"

printf 'all tests passed\n'
