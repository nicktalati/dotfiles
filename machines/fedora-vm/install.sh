#!/usr/bin/env bash

set -Eeuo pipefail

readonly dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
readonly machine_dir="$dotfiles_dir/machines/fedora-vm"
readonly stow_dir="$dotfiles_dir/stow"
readonly xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly oauth_dir="$HOME/.local/share/mail/oauth"

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

(($# == 0)) || die "install.sh takes no arguments"
[[ "$EUID" -ne 0 ]] || die "do not run this script as root"
[[ -d "$dotfiles_dir/.git" ]] || die "dotfiles repository not found at $dotfiles_dir"
[[ -r /etc/os-release ]] || die "cannot identify this operating system"
# shellcheck source=/dev/null
source /etc/os-release
[[ "$ID" == fedora ]] || die "fedora-vm install requires Fedora"

"$machine_dir/install-packages.sh"

command -v stow &>/dev/null || die "stow is required"

mkdir -p "$xdg_config_home/dotfiles" "$HOME/mail" "$oauth_dir"
chmod 700 "$oauth_dir"
# NeoMutt's sidebar section headers are local-only pseudo-Maildirs no program
# creates: mbsync only creates mailboxes that exist remotely.
mkdir -p "$HOME"/mail/.header-{cultivate,nicktalati}/{cur,new,tmp}
printf '%s\n' fedora-vm > "$xdg_config_home/dotfiles/machine"

stow --restow --no-folding --dir "$stow_dir" --target "$HOME" \
    shell nvim tmux git mail psql task backup \
    account-cultivate account-personal

zsh_path=$(command -v zsh)
current_shell=$(getent passwd "$USER" | cut -d: -f7)
if [[ "$current_shell" != "$zsh_path" ]]; then
    sudo usermod --shell "$zsh_path" "$USER"
    printf 'warning: the zsh login shell takes effect in a new session\n' >&2
fi

# Without lingering, the user systemd instance runs only while a session is
# open: mail timers and goimapnotify would stop on detach and would not start
# after a reboot until the next login.
sudo loginctl enable-linger "$USER"

# Docker group membership grants non-root access to the Docker socket.
if ! id -nG "$USER" | tr ' ' '\n' | grep -Fxq docker; then
    sudo usermod -aG docker "$USER"
    printf 'warning: Docker group membership takes effect in a new session\n' >&2
fi
sudo systemctl enable --now docker.service

systemctl --user daemon-reload
if [[ -S /run/host-services/ssh-auth.sock ]]; then
    printf 'Using the SSH agent forwarded by Lima.\n'
else
    systemctl --user enable --now ssh-agent.service
fi
systemctl --user enable --now backup.timer

# The mail units gate themselves on OAuth-token presence through
# ConditionPathExists, so every account is enabled unconditionally; a unit
# whose token is absent is skipped, not failed.
systemctl --user enable --now \
    mbsync@{cultivate,personal}.timer \
    goimapnotify@{cultivate,personal}.service

cat <<EOF

Fedora VM installation complete.

OAuth tokens are local, writable files under:

    $oauth_dir

Mail units run only for accounts whose token file exists. After adding a
token, mbsync resumes on its next timer fire; start push notifications
immediately with:

    systemctl --user start goimapnotify@<account>.service

Put repositories under ~/code/personal or ~/code/cultivate so Git selects the
corresponding identity.
EOF
