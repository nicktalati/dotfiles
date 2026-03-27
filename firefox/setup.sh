#!/bin/bash

set -Eeuo pipefail

readonly script_dir="$(cd "$(dirname "$0")" && pwd)"
readonly firefox_dir="$HOME/.mozilla/firefox"

# Copy profiles.ini only if absent — Firefox appends an [Install] section on
# first launch that we don't want to clobber on re-runs.
if [[ ! -f "$firefox_dir/profiles.ini" ]]; then
    mkdir -p "$firefox_dir"
    cp "$script_dir/profiles.ini" "$firefox_dir/profiles.ini"
fi

# Set up each profile found under profiles/
for profile_dir in "$script_dir"/profiles/*/; do
    profile="$(basename "$profile_dir")"
    target="$firefox_dir/$profile"

    mkdir -p "$target/chrome"
    ln -sf "$profile_dir/user.js" "$target/user.js"

    if [[ -d "$profile_dir/chrome" ]]; then
        for f in "$profile_dir"/chrome/*; do
            ln -sf "$f" "$target/chrome/$(basename "$f")"
        done
    fi
done

# System-wide policies (extensions, telemetry, etc.)
sudo mkdir -p /etc/firefox/policies
sudo cp "$script_dir/policies.json" /etc/firefox/policies/policies.json

echo "Firefox setup complete. Launch each profile and sign in."
