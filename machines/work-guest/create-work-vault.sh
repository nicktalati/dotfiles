#!/usr/bin/env bash

set -Eeuo pipefail

usage() {
    cat <<'EOF'
Usage: create-work-vault.sh SOURCE_SECRETS DEST_CIPHERTEXT

Create a new gocryptfs vault containing only the known Cultivate mail and SSH
credentials from an already-mounted source vault.

Example:
  ./create-work-vault.sh ~/decrypt/secrets ~/crypt-work

DEST_CIPHERTEXT must not exist or must be empty. The script initializes it,
mounts it temporarily, copies an explicit allowlist, and unmounts it. It does
not upload the ciphertext or create a gocryptfs passphrase file.
EOF
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

[[ "$#" -eq 2 ]] || {
    usage >&2
    exit 2
}

source_secrets=$(realpath -e -- "$1")
readonly source_secrets
destination_ciphertext=$(realpath -m -- "$2")
readonly destination_ciphertext

command -v gocryptfs &>/dev/null || die "gocryptfs is not installed"
command -v fusermount3 &>/dev/null || die "fusermount3 is not installed"

[[ -d "$source_secrets" ]] || die "source secrets directory does not exist"
if [[ -e "$destination_ciphertext" && -n "$(find "$destination_ciphertext" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
    die "destination must not exist or must be empty: $destination_ciphertext"
fi

readonly oauth_source="$source_secrets/oauth/cultivate.oauth2"
readonly ssh_source="$source_secrets/ssh"
readonly -a required_sources=(
    "$oauth_source"
    "$ssh_source/config.d/work"
    "$ssh_source/id_rsa_work_github"
    "$ssh_source/id_rsa_work_github.pub"
    "$ssh_source/id_rsa_work_gitlab"
    "$ssh_source/id_rsa_work_gitlab.pub"
)

for source_path in "${required_sources[@]}"; do
    [[ -f "$source_path" ]] || die "required source file is missing: $source_path"
done

mount_dir=$(mktemp -d)
mounted=false

cleanup() {
    if $mounted; then
        fusermount3 -u -- "$mount_dir" || true
    fi
    rmdir -- "$mount_dir" 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p -- "$destination_ciphertext"

printf 'Initializing work-only vault at %s\n' "$destination_ciphertext"
gocryptfs -init "$destination_ciphertext"
gocryptfs "$destination_ciphertext" "$mount_dir"
mounted=true

install -d -m 700 "$mount_dir/secrets/oauth" "$mount_dir/secrets/ssh/config.d"
install -m 600 "$oauth_source" "$mount_dir/secrets/oauth/cultivate.oauth2"
install -m 600 "$ssh_source/config.d/work" "$mount_dir/secrets/ssh/config.d/work"
install -m 600 "$ssh_source/id_rsa_work_github" "$mount_dir/secrets/ssh/id_rsa_work_github"
install -m 644 "$ssh_source/id_rsa_work_github.pub" "$mount_dir/secrets/ssh/id_rsa_work_github.pub"
install -m 600 "$ssh_source/id_rsa_work_gitlab" "$mount_dir/secrets/ssh/id_rsa_work_gitlab"
install -m 644 "$ssh_source/id_rsa_work_gitlab.pub" "$mount_dir/secrets/ssh/id_rsa_work_gitlab.pub"

install -m 600 /dev/null "$mount_dir/secrets/secrets.zsh"

fusermount3 -u -- "$mount_dir"
mounted=false

cat <<EOF

Created the work-only ciphertext at:
  $destination_ciphertext

The new secrets.zsh is intentionally empty. Mount the vault locally and add
only work-specific shell secrets after reviewing the current mixed file.

Next, choose a distinct rclone/S3 prefix, upload this ciphertext, sync it to
~/crypt in the guest, and enroll the gocryptfs passphrase there.
EOF
