#!/usr/bin/env bash

set -Eeuo pipefail

readonly dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"
readonly shared_machine_dir="$dotfiles_dir/machines/work-guest"
readonly xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly xdg_state_home="${XDG_STATE_HOME:-$HOME/.local/state}"

configure_only=false

usage() {
    cat <<'EOF'
Usage: install_work_guest.sh [--configure-only]

  --configure-only  Restow and render user configuration without installing
                    packages, changing the login shell, or enabling services.
EOF
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

info() {
    printf '==> %s\n' "$*"
}

warn() {
    printf 'warning: %s\n' "$*" >&2
}

while (($#)); do
    case "$1" in
        --configure-only)
            configure_only=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            die "unknown argument: $1"
            ;;
    esac
    shift
done

[[ "$EUID" -ne 0 ]] || die "do not run this script as root"
[[ -r /etc/os-release ]] || die "cannot identify this operating system"
# shellcheck source=/dev/null
source /etc/os-release

case "$ID" in
    arch|archarm)
        readonly machine=arch-work-guest
        ;;
    fedora)
        readonly machine=fedora-work-guest
        ;;
    *)
        die "unsupported work guest operating system: $ID"
        ;;
esac

readonly machine_dir="$dotfiles_dir/machines/$machine"
readonly package_list="$machine_dir/packages.txt"

[[ -d "$dotfiles_dir/.git" ]] || die "dotfiles repository not found at $dotfiles_dir"
[[ -f "$package_list" ]] || die "package list not found at $package_list"

install_arch_packages() {
    local -a local_packages=(
        aws-session-manager-plugin
        cyrus-sasl-xoauth2
    )
    if [[ "$(uname -m)" == aarch64 ]]; then
        local_packages+=(shellcheck)
    fi

    info "Updating Arch and installing repository packages"
    grep -Fvx -f <(printf '%s\n' "${local_packages[@]}") "$package_list" | \
        sudo pacman -Syu --needed --noconfirm -

    local local_package
    for local_package in "${local_packages[@]}"; do
        pacman -Q "$local_package" &>/dev/null && continue

        local build_dir
        build_dir=$(mktemp -d)
        cp "$machine_dir/packages/$local_package/PKGBUILD" "$build_dir/PKGBUILD"
        if ! (
            cd "$build_dir"
            makepkg -si --noconfirm
        ); then
            rm -rf -- "$build_dir"
            die "failed to build $local_package"
        fi
        rm -rf -- "$build_dir"
    done
}

install_fedora_packages() {
    local -a local_packages=(session-manager-plugin)
    local -a packages
    mapfile -t packages < <(
        grep -Fvx -f <(printf '%s\n' "${local_packages[@]}") "$package_list"
    )

    info "Updating Fedora and installing repository packages"
    sudo dnf --refresh -y upgrade
    sudo dnf -y install "${packages[@]}"
    "$machine_dir/install-tools.sh"
}

install_packages() {
    case "$machine" in
        arch-work-guest)
            install_arch_packages
            ;;
        fedora-work-guest)
            install_fedora_packages
            ;;
    esac
}

prepare_directories() {
    mkdir -p \
        "$xdg_config_home/dotfiles" \
        "$xdg_config_home/gocryptfs" \
        "$xdg_config_home/notmuch/default" \
        "$xdg_config_home/rclone" \
        "$xdg_config_home/zsh" \
        "$xdg_state_home/msmtp" \
        "$xdg_state_home/node" \
        "$xdg_state_home/nvim/undo" \
        "$xdg_state_home/notify-mail" \
        "$xdg_state_home/psql" \
        "$xdg_state_home/python" \
        "$xdg_state_home/zsh" \
        "$HOME/.ssh/config.d" \
        "$HOME/code" \
        "$HOME/crypt" \
        "$HOME/decrypt" \
        "$HOME/downloads" \
        "$HOME/mail/.header-cultivate/cur" \
        "$HOME/mail/.header-cultivate/new" \
        "$HOME/mail/.header-cultivate/tmp"

    local -a cultivate_mailboxes=(
        Inbox
        product
        infra
        hiring
        financial
        'hr and legal'
        filene
        receipts
        DMARC
        '[Gmail]/Sent Mail'
        '[Gmail]/Drafts'
        '[Gmail]/Spam'
        '[Gmail]/All Mail'
        '[Gmail]/Trash'
    )
    local mailbox
    for mailbox in "${cultivate_mailboxes[@]}"; do
        mkdir -p "$HOME/mail/cultivate/$mailbox"/{cur,new,tmp}
    done

    printf '%s\n' "$machine" > "$xdg_config_home/dotfiles/machine"
}

stow_configuration() {
    local -a common_options=(
        --restow
        --no-folding
        --dir "$dotfiles_dir"
        --target "$HOME"
    )
    local -a core_ignores=(
        '--ignore=^\.config/backup/config$'
        '--ignore=^\.config/git/config$'
        '--ignore=^\.config/systemd/user/crypt-backup\.(service|timer)$'
        '--ignore=^\.config/tmux/tmux\.conf$'
        '--ignore=^\.config/zsh/\.zprofile$'
        '--ignore=^\.local/bin/(backup_drive|mount_drive|unmount_drive)$'
        '--ignore=^\.ssh/config$'
    )
    local -a email_ignores=(
        '--ignore=^\.config/goimapnotify/goimapnotify\.yaml$'
        '--ignore=^\.config/isyncrc$'
        '--ignore=^\.config/msmtp/config$'
        '--ignore=^\.config/neomutt/neomuttrc$'
        '--ignore=^\.config/notmuch/default/config$'
    )

    info "Stowing reusable and work-only configuration"
    stow "${common_options[@]}" "${core_ignores[@]}" core
    stow "${common_options[@]}" "${email_ignores[@]}" email
    stow "${common_options[@]}" work-guest
    if [[ -d "$dotfiles_dir/$machine" ]]; then
        stow "${common_options[@]}" "$machine"
    fi
}

render_machine_configuration() {
    local template="$shared_machine_dir/notmuch-config.template"
    local target="$xdg_config_home/notmuch/default/config"
    local escaped_mail_dir=$HOME
    escaped_mail_dir=${escaped_mail_dir//&/\\&}
    escaped_mail_dir=${escaped_mail_dir//|/\\|}

    sed "s|@MAIL_DIR@|$escaped_mail_dir/mail|g" "$template" > "$target"

    local rclone_template="$dotfiles_dir/core/.config/rclone/rclone.conf.template"
    local rclone_config="$xdg_config_home/rclone/rclone.conf"
    if [[ ! -e "$rclone_config" ]]; then
        install -m 600 "$rclone_template" "$rclone_config"
    fi
}

link_work_secrets() {
    local secrets_dir="$HOME/decrypt/secrets"
    local -a ssh_paths=(
        config.d/work
        id_rsa_work_github
        id_rsa_work_github.pub
        id_rsa_work_gitlab
        id_rsa_work_gitlab.pub
    )

    ln -sfn "$secrets_dir/secrets.zsh" "$xdg_config_home/zsh/secrets.zsh"
    local path
    for path in "${ssh_paths[@]}"; do
        mkdir -p "$HOME/.ssh/$(dirname "$path")"
        ln -sfn "$secrets_dir/ssh/$path" "$HOME/.ssh/$path"
    done
}

configure_services() {
    info "Configuring Docker and user services"
    sudo loginctl enable-linger "$USER"

    if ! id -nG "$USER" | tr ' ' '\n' | grep -Fxq docker; then
        sudo usermod -aG docker "$USER"
        warn "Docker group membership takes effect in a new login session"
    fi
    sudo systemctl enable --now docker.service

    systemctl --user daemon-reload
    systemctl --user enable --now ssh-agent.service
    systemctl --user enable --now zsh-hist-backup.timer

    if [[ -f "$xdg_config_home/gocryptfs/secrets" && -f "$HOME/crypt/gocryptfs.conf" ]]; then
        systemctl --user enable --now crypt-mount.service
    else
        warn "work vault is not enrolled; crypt-mount.service remains disabled"
    fi

    if [[ -f "$HOME/decrypt/secrets/oauth/cultivate.oauth2" ]]; then
        systemctl --user enable --now mbsync.timer
        systemctl --user enable --now goimapnotify@work.service
    else
        warn "Cultivate OAuth token is unavailable; mail services remain disabled"
    fi
}

change_login_shell() {
    local zsh_path
    zsh_path=$(command -v zsh)
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [[ "$current_shell" != "$zsh_path" ]]; then
        sudo usermod --shell "$zsh_path" "$USER"
        warn "the zsh login shell takes effect in a new login session"
    fi
}

if ! $configure_only; then
    install_packages
fi

command -v stow &>/dev/null || die "stow is required; install it or omit --configure-only"

prepare_directories
stow_configuration
render_machine_configuration
link_work_secrets

if ! $configure_only; then
    change_login_shell
    configure_services
    "$HOME/.local/bin/dotfiles-doctor"
else
    info "Configuration-only installation complete"
fi

cat <<EOF

$machine provisioning complete.

Next:
  1. Enroll the work-only gocryptfs/rclone vault.
  2. Rerun this script to enable the mount and mail services.
  3. Clone a real work repository and exercise its full test stack.
  4. Run dotfiles-doctor after any configuration change.
EOF
