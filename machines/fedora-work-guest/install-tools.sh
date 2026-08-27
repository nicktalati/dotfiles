#!/usr/bin/env bash

set -Eeuo pipefail

readonly opt_dir="$HOME/.local/opt"
readonly dbmate_version=2.35.0
readonly fnm_version=1.39.0
readonly luals_version=3.19.1
readonly goimapnotify_version=2.5.8
readonly session_manager_version=1.2.835.0
export GOCACHE="${XDG_CACHE_HOME:-$HOME/.cache}/go/build"
export GOMODCACHE="${XDG_CACHE_HOME:-$HOME/.cache}/go/mod"

temp_dir=$(mktemp -d)
readonly temp_dir
trap 'rm -rf -- "$temp_dir"' EXIT

download() {
    local url=$1
    local sha256=$2
    local destination=$3

    curl --fail --location --silent --show-error --output "$destination" "$url"
    printf '%s  %s\n' "$sha256" "$destination" | sha256sum --check --status || {
        printf 'error: checksum failed for %s\n' "$url" >&2
        exit 1
    }
}

case "$(uname -m)" in
    aarch64)
        readonly dbmate_asset=dbmate-linux-arm64
        readonly dbmate_sha256=9aac97323334c252bc1ea7d49f3fcb67ae54636b4af6f9045b8d229027c564d6
        readonly fnm_asset=fnm-arm64.zip
        readonly fnm_sha256=4eaff58b2c5bf30d0934027572dd0b5bbb60d2a1af309230b53662d4b1d45599
        readonly luals_asset=lua-language-server-3.19.1-linux-arm64.tar.gz
        readonly luals_sha256=abd2572e8fc929dc838a81ffb8473c5bce0bf39bfe8edb4b120b3b623176ce83
        readonly session_manager_asset=linux_arm64
        readonly session_manager_sha256=f2b06a6627563bd9af1a5494c750affc72907ced1f982ceacee54d1e3b8c3eb1
        ;;
    x86_64)
        readonly dbmate_asset=dbmate-linux-amd64
        readonly dbmate_sha256=f60fd6c6dbed316de116a701945a3fb21d365a25a7e6a9b28ba3a50f49818d8f
        readonly fnm_asset=fnm-linux.zip
        readonly fnm_sha256=7807664f39d39fc518da1c35ba0181e4b3267603c4b1dedeb4b5fc6ae440a224
        readonly luals_asset=lua-language-server-3.19.1-linux-x64.tar.gz
        readonly luals_sha256=e9235d2d72ef55bc41cf8c99cda2ed64777682024b4bb81f5dea425060c5cbb8
        readonly session_manager_asset=linux_64bit
        readonly session_manager_sha256=1dcade7435709cce65a05eba87f2a96e8aaf7318c78a21d7a2ae648ce2f2ad81
        ;;
    *)
        printf 'error: unsupported architecture: %s\n' "$(uname -m)" >&2
        exit 1
        ;;
esac

mkdir -p "$opt_dir"

dbmate_dir="$opt_dir/dbmate-$dbmate_version"
if [[ ! -x "$dbmate_dir/dbmate" ]]; then
    mkdir -p "$dbmate_dir"
    download \
        "https://github.com/amacneil/dbmate/releases/download/v$dbmate_version/$dbmate_asset" \
        "$dbmate_sha256" "$temp_dir/dbmate"
    install -m 755 "$temp_dir/dbmate" "$dbmate_dir/dbmate"
fi

fnm_dir="$opt_dir/fnm-$fnm_version"
if [[ ! -x "$fnm_dir/fnm" ]]; then
    mkdir -p "$fnm_dir"
    download \
        "https://github.com/Schniz/fnm/releases/download/v$fnm_version/$fnm_asset" \
        "$fnm_sha256" "$temp_dir/fnm.zip"
    unzip -q "$temp_dir/fnm.zip" -d "$fnm_dir"
fi

luals_dir="$opt_dir/lua-language-server-$luals_version"
if [[ ! -x "$luals_dir/bin/lua-language-server" ]]; then
    mkdir -p "$luals_dir"
    download \
        "https://github.com/LuaLS/lua-language-server/releases/download/$luals_version/$luals_asset" \
        "$luals_sha256" "$temp_dir/luals.tar.gz"
    tar -xzf "$temp_dir/luals.tar.gz" -C "$luals_dir"
fi

goimapnotify_dir="$opt_dir/goimapnotify-$goimapnotify_version"
if [[ ! -x "$goimapnotify_dir/goimapnotify" ]]; then
    download \
        "https://gitlab.com/shackra/goimapnotify/-/archive/$goimapnotify_version/goimapnotify-$goimapnotify_version.tar.gz" \
        616aae1f48fbe4e2afffd968e7c393d32075365a0a94aa7654ab7abe4b4ac1c6 \
        "$temp_dir/goimapnotify.tar.gz"
    tar -xzf "$temp_dir/goimapnotify.tar.gz" -C "$temp_dir"
    mkdir -p "$goimapnotify_dir"
    (
        cd "$temp_dir/goimapnotify-$goimapnotify_version"
        go build -trimpath \
            -ldflags "-s -w -X main.gittag=$goimapnotify_version" \
            -o "$goimapnotify_dir/goimapnotify" \
            ./cmd/goimapnotify
    )
fi

installed_session_manager=$(rpm -q --queryformat '%{VERSION}' session-manager-plugin 2>/dev/null || true)
if [[ "$installed_session_manager" != "$session_manager_version" ]]; then
    session_manager_rpm="$temp_dir/session-manager-plugin.rpm"
    download \
        "https://s3.amazonaws.com/session-manager-downloads/plugin/$session_manager_version/$session_manager_asset/session-manager-plugin.rpm" \
        "$session_manager_sha256" "$session_manager_rpm"
    sudo dnf -y install "$session_manager_rpm"
fi
