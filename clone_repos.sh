#!/bin/bash

set -euo pipefail

readonly code_dir="$HOME/code"
mkdir -p "$code_dir"
cd "$code_dir"

REPOS=(
    "git@personal:nicktalati/blog"
    "git@personal:nicktalati/cloud-dev-env"
    "git@personal:nicktalati/digitalneuron"
    "git@personal:pia-foss/manual-connections.git"
)

for repo in "${REPOS[@]}"; do
    dir_name=$(basename "$repo" .git)
    if [ ! -d "$dir_name" ]; then
        echo "Cloning $dir_name..."
        git clone "$repo"
    else
        echo "$dir_name already exists."
    fi
done
