#!/usr/bin/env bash

set -Eeuo pipefail

machine_dir=$(cd "$(dirname "$0")" && pwd)
readonly machine_dir
readonly lock_file="$machine_dir/tools.lock.json"
readonly opt_dir="$HOME/.local/opt"
readonly bin_dir="$HOME/.local/bin"
architecture=$(uname -m)
readonly architecture

export GOCACHE="${XDG_CACHE_HOME:-$HOME/.cache}/go/build"
export GOMODCACHE="${XDG_CACHE_HOME:-$HOME/.cache}/go/mod"

case "$architecture" in
    aarch64|x86_64) ;;
    *)
        printf 'error: unsupported architecture: %s\n' "$architecture" >&2
        exit 1
        ;;
esac

[[ -f "$lock_file" ]] || {
    printf 'error: tool lock file is missing: %s\n' "$lock_file" >&2
    exit 1
}

temp_dir=$(mktemp -d)
readonly temp_dir
trap 'rm -rf -- "$temp_dir"' EXIT

lock_value() {
    local filter=$1
    jq --exit-status --raw-output "$filter" "$lock_file"
}

tool_version() {
    lock_value ".\"$1\".version"
}

asset_value() {
    lock_value ".\"$1\".assets.\"$architecture\".$2"
}

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

mkdir -p "$opt_dir" "$bin_dir"

dbmate_version=$(tool_version dbmate)
dbmate_asset=$(asset_value dbmate name)
dbmate_sha256=$(asset_value dbmate sha256)
dbmate_dir="$opt_dir/dbmate-$dbmate_version"
if [[ ! -x "$dbmate_dir/dbmate" ]]; then
    mkdir -p "$dbmate_dir"
    download \
        "https://github.com/amacneil/dbmate/releases/download/v$dbmate_version/$dbmate_asset" \
        "$dbmate_sha256" "$temp_dir/dbmate"
    install -m 755 "$temp_dir/dbmate" "$dbmate_dir/dbmate"
fi
ln -sfn "$dbmate_dir/dbmate" "$bin_dir/dbmate"

fnm_version=$(tool_version fnm)
fnm_asset=$(asset_value fnm name)
fnm_sha256=$(asset_value fnm sha256)
fnm_dir="$opt_dir/fnm-$fnm_version"
if [[ ! -x "$fnm_dir/fnm" ]]; then
    mkdir -p "$fnm_dir"
    download \
        "https://github.com/Schniz/fnm/releases/download/v$fnm_version/$fnm_asset" \
        "$fnm_sha256" "$temp_dir/fnm.zip"
    unzip -q "$temp_dir/fnm.zip" -d "$fnm_dir"
fi
ln -sfn "$fnm_dir/fnm" "$bin_dir/fnm"

# Neovim's Markdown tooling is not a release binary: nvim-lint runs
# markdownlint, an npm package, and conform runs mdformat, a Python one. Node
# was previously installed by hand, which is why a rebuilt VM linted nothing
# and silently skipped formatting; pin all three. fnm checks Node's published
# checksums and uv checks PyPI's, so neither needs an entry here.
node_version=$(tool_version node)
if [[ ! -d "${XDG_DATA_HOME:-$HOME/.local/share}/fnm/node-versions/v$node_version" ]]; then
    "$bin_dir/fnm" install "$node_version"
fi
"$bin_dir/fnm" default "$node_version"

markdownlint_version=$(tool_version markdownlint-cli)
markdownlint_dir="$opt_dir/markdownlint-cli-$markdownlint_version"
if [[ ! -x "$markdownlint_dir/bin/markdownlint" ]]; then
    "$bin_dir/fnm" exec --using "$node_version" -- \
        npm install --silent --global --prefix "$markdownlint_dir" \
        "markdownlint-cli@$markdownlint_version"
fi
ln -sfn "$markdownlint_dir/bin/markdownlint" "$bin_dir/markdownlint"

mdformat_version=$(tool_version mdformat)
installed_mdformat=$("$bin_dir/mdformat" --version 2>/dev/null | awk '{ print $2 }')
if [[ "$installed_mdformat" != "$mdformat_version" ]]; then
    uv tool install --force --quiet "mdformat==$mdformat_version"
fi

luals_version=$(tool_version lua-language-server)
luals_asset=$(asset_value lua-language-server name)
luals_sha256=$(asset_value lua-language-server sha256)
luals_dir="$opt_dir/lua-language-server-$luals_version"
if [[ ! -x "$luals_dir/bin/lua-language-server" ]]; then
    mkdir -p "$luals_dir"
    download \
        "https://github.com/LuaLS/lua-language-server/releases/download/$luals_version/$luals_asset" \
        "$luals_sha256" "$temp_dir/luals.tar.gz"
    tar -xzf "$temp_dir/luals.tar.gz" -C "$luals_dir"
fi
ln -sfn "$luals_dir" "$opt_dir/lua-language-server"
install -m 755 "$machine_dir/lua-language-server" "$bin_dir/lua-language-server"

goimapnotify_version=$(tool_version goimapnotify)
goimapnotify_sha256=$(lock_value '.goimapnotify.sha256')
goimapnotify_dir="$opt_dir/goimapnotify-$goimapnotify_version"
if [[ ! -x "$goimapnotify_dir/goimapnotify" ]]; then
    download \
        "https://gitlab.com/shackra/goimapnotify/-/archive/$goimapnotify_version/goimapnotify-$goimapnotify_version.tar.gz" \
        "$goimapnotify_sha256" "$temp_dir/goimapnotify.tar.gz"
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
ln -sfn "$goimapnotify_dir/goimapnotify" "$bin_dir/goimapnotify"

session_manager_version=$(tool_version session-manager-plugin)
installed_session_manager=$(rpm -q --queryformat '%{VERSION}' session-manager-plugin 2>/dev/null || true)
if [[ "$installed_session_manager" != "$session_manager_version" ]]; then
    session_manager_asset=$(asset_value session-manager-plugin name)
    session_manager_sha256=$(asset_value session-manager-plugin sha256)
    session_manager_rpm="$temp_dir/session-manager-plugin.rpm"
    download \
        "https://s3.amazonaws.com/session-manager-downloads/plugin/$session_manager_version/$session_manager_asset/session-manager-plugin.rpm" \
        "$session_manager_sha256" "$session_manager_rpm"
    sudo dnf -y install "$session_manager_rpm"
fi
