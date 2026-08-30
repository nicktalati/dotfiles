#!/usr/bin/env bash

# Gmail requires XOAUTH2, and isync implements no OAuth of its own: it asks
# Cyrus SASL for the mechanism. Two unrelated plugins publish the name XOAUTH2
# and disagree about what the password is.
#
#   moriyoshi/cyrus-sasl-xoauth2  the password is an access token
#   tarickb/sasl-xoauth2          the password is a path to a token file the
#                                 plugin refreshes itself; written for Postfix
#
# The shared isync configuration hands mbsync an access token through PassCmd,
# which is the first plugin's contract. Arch packages that one as
# cyrus-sasl-xoauth2-git. Fedora packages only the second, which fails every
# authentication with "Unable to find a callback: 32775" no matter what the
# password is, because it asks Cyrus SASL for a callback isync does not
# register. Both plugins installed at once is also a losing position: the
# Postfix one wins the name.
#
# So Fedora builds the plugin it does not package, from a pinned and
# checksummed source archive, and refuses to leave the incompatible one in
# place.

set -Eeuo pipefail

machine_dir=$(cd "$(dirname "$0")" && pwd)
readonly machine_dir
readonly lock_file="$machine_dir/tools.lock.json"
readonly plugin_dir=/usr/lib64/sasl2
readonly plugin="$plugin_dir/libxoauth2.so"
readonly incompatible_plugin="$plugin_dir/libsasl-xoauth2.so"
readonly stamp=/usr/local/share/cyrus-sasl-xoauth2/version

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

[[ -f "$lock_file" ]] || die "tool lock file is missing: $lock_file"

version=$(jq --exit-status --raw-output '."cyrus-sasl-xoauth2".version' "$lock_file")
url=$(jq --exit-status --raw-output '."cyrus-sasl-xoauth2".source.url' "$lock_file")
sha256=$(jq --exit-status --raw-output '."cyrus-sasl-xoauth2".source.sha256' "$lock_file")
readonly version url sha256

# The Postfix plugin is not merely unused; while it is installed it answers for
# XOAUTH2 and mbsync cannot authenticate at all.
if rpm --query --quiet sasl-xoauth2; then
    printf 'Removing the incompatible sasl-xoauth2 plugin...\n'
    sudo dnf -y remove sasl-xoauth2
fi
[[ ! -e "$incompatible_plugin" ]] || \
    die "$incompatible_plugin remains and will shadow the compatible plugin"

if [[ -x "$plugin" && -f "$stamp" && "$(cat "$stamp")" == "$version" ]]; then
    exit 0
fi

temp_dir=$(mktemp -d)
readonly temp_dir
trap 'rm -rf -- "$temp_dir"' EXIT

printf 'Building cyrus-sasl-xoauth2 %s...\n' "${version:0:12}"
curl --fail --location --silent --show-error \
    --output "$temp_dir/source.tar.gz" "$url"
printf '%s  %s\n' "$sha256" "$temp_dir/source.tar.gz" | sha256sum --check --status || \
    die "checksum failed for $url"

tar --extract --gzip --file "$temp_dir/source.tar.gz" --directory "$temp_dir"
source_dir="$temp_dir/cyrus-sasl-xoauth2-$version"
[[ -d "$source_dir" ]] || die "unexpected archive layout for $url"

(
    cd "$source_dir"
    ./autogen.sh
    ./configure --prefix=/usr --libdir=/usr/lib64
    make
) >"$temp_dir/build.log" 2>&1 || {
    tail -20 "$temp_dir/build.log" >&2
    die "cyrus-sasl-xoauth2 did not build"
}

sudo install -m 755 "$source_dir/.libs/libxoauth2.so.0.0.0" "$plugin"
sudo install -D -m 644 /dev/stdin "$stamp" <<<"$version"
printf 'Installed %s\n' "$plugin"
