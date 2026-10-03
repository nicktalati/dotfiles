#!/usr/bin/env bash

set -Eeuo pipefail

readonly dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
readonly brewfile="$dotfiles_dir/machines/mac-host/Brewfile"

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

(($# == 0)) || die "bootstrap.sh takes no arguments"
[[ "$(uname -s)" == Darwin ]] || die "mac-host requires macOS"
[[ "$EUID" -ne 0 ]] || die "do not run this script as root"
[[ -d "$dotfiles_dir/.git" ]] || die "dotfiles repository not found at $dotfiles_dir"
command -v brew &>/dev/null || die "Homebrew is not installed or is not on PATH"

brew bundle install --no-upgrade --file "$brewfile"

stow --restow --no-folding --dir "$dotfiles_dir/stow" --target "$HOME" \
    macos wallpaper

# launchd expands neither ~ nor $HOME, so the agent that shows the VM's
# notifications is written for this home rather than stowed.
readonly agent=com.nicktalati.vm-notify
readonly agent_plist="$HOME/Library/LaunchAgents/$agent.plist"
mkdir -p "${agent_plist%/*}"
cat > "$agent_plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$agent</string>
    <key>ProgramArguments</key>
    <array>
        <string>$HOME/.local/bin/vm-notify</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>30</integer>
</dict>
</plist>
EOF
launchctl bootstrap "gui/$UID" "$agent_plist" 2>/dev/null || \
    launchctl kickstart -k "gui/$UID/$agent"

fdesetup status | grep -q 'FileVault is On' || \
    printf 'warning: FileVault is not enabled\n' >&2

cat <<'EOF'

mac-host bootstrap complete. Create and provision the guest next:

    ~/dotfiles/machines/fedora-vm/create-lima.sh
    limactl shell dev
    ~/dotfiles/machines/fedora-vm/install.sh

Then open a new shell and enter the environment with: dev
EOF
