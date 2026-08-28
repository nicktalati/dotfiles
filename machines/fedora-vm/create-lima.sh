#!/usr/bin/env bash

set -Eeuo pipefail

readonly instance="${LIMA_INSTANCE:-dev}"
readonly cpus="${LIMA_CPUS:-6}"
readonly memory_gib="${LIMA_MEMORY_GIB:-8}"
readonly disk_gib="${LIMA_DISK_GIB:-100}"
readonly vm_type="${LIMA_VM_TYPE:-}"
readonly repository="${DOTFILES_REPOSITORY:-git@github.com:nicktalati/dotfiles.git}"
machine_dir=$(cd "$(dirname "$0")" && pwd)
readonly machine_dir

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

command -v limactl &>/dev/null || die "limactl is not installed"

instance_exists() {
    limactl list --format '{{.Name}}' 2>/dev/null | grep -Fxq "$instance"
}

if ! instance_exists; then
    printf 'Creating Lima instance %s...\n' "$instance"
    create_args=(
        --tty=false
        --name "$instance"
        --cpus "$cpus"
        --memory "$memory_gib"
        --disk "$disk_gib"
        --mount-none
        --containerd none
    )
    if [[ -n "$vm_type" ]]; then
        create_args+=(--vm-type "$vm_type")
    fi
    limactl create "${create_args[@]}" "$machine_dir/lima.yaml"
fi

instance_status=$(limactl list --format '{{.Name}} {{.Status}}' | awk -v name="$instance" '$1 == name { print $2 }')
if [[ "$instance_status" != Running ]]; then
    limactl start "$instance"
fi

limactl shell "$instance" -- sudo dnf --refresh -y install git
# The single-quoted program is intentionally expanded by bash inside the guest,
# where DOTFILES_REPOSITORY and HOME have the desired values.
# shellcheck disable=SC2016
limactl shell "$instance" -- env DOTFILES_REPOSITORY="$repository" bash -lc '
    if [[ ! -d "$HOME/dotfiles/.git" ]]; then
        git clone "$DOTFILES_REPOSITORY" "$HOME/dotfiles"
    fi
'

cat <<EOF

The $instance VM is running and the dotfiles repository is present.

Enter it with:

    limactl shell $instance

Then provision it with:

    ~/dotfiles/machines/fedora-vm/install.sh

The VM has no host-directory mounts. Its repositories and mutable state live
on the guest disk; commit or back up valuable work before deleting the VM.
EOF
