#!/bin/bash

CODE_DIR="$HOME/code"
mkdir -p "$CODE_DIR"
cd "$CODE_DIR"

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
