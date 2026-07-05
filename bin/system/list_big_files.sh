#!/bin/bash

# Script to list big files recursively with directory pruning based on size
# Usage: ./list_big_files.sh [root_directory]

# Configuration
MIN_FILE_SIZE_MB=50        # List files larger than this
FOLDER_THRESHOLD_MB=100    # Prune directories smaller than this
MAX_DEPTH=20
ROOT_DIR="${1:-$HOME}"

# Ensure root dir exists
if [ ! -d "$ROOT_DIR" ]; then
    echo "Error: Directory $ROOT_DIR not found."
    exit 1
fi

get_size_mb() {
    # du -sm returns "SizeInMB   Path"
    # use awk to handle both space and tab separators
    du -sm "$1" 2>/dev/null | awk '{print $1}'
}

get_file_size_bytes() {
    # wc -c < file is a very portable way to get file size in bytes
    wc -c < "$1" 2>/dev/null | awk '{print $1}'
}

scan_dir() {
    local dir="$1"
    local depth="$2"

    # Max depth check
    if (( depth > MAX_DEPTH )); then
        return
    fi

    # Directory size check
    # Note: This operation can be slow as it calculates size recursively
    local dir_size
    dir_size=$(get_size_mb "$dir")

    # If du failed (e.g. permissions), skip
    if [[ -z "$dir_size" ]]; then
        return
    fi

    # Prune if small
    if (( dir_size < FOLDER_THRESHOLD_MB )); then
        # echo "Skipping $dir (Size: ${dir_size}MB)"
        return
    fi

    # List the folder itself
    echo "${dir_size}MB: $dir/"

    # Iterate contents
    # Enable nullglob to handle empty directories gracefully
    shopt -s nullglob
    local children=("$dir"/*)
    shopt -u nullglob

    for entry in "${children[@]}"; do
        if [ -d "$entry" ]; then
            scan_dir "$entry" $((depth + 1))
        elif [ -f "$entry" ]; then
            local fsize_bytes
            fsize_bytes=$(get_file_size_bytes "$entry")

            if [[ -n "$fsize_bytes" ]]; then
                local fsize_mb=$((fsize_bytes / 1024 / 1024))
                if (( fsize_mb >= MIN_FILE_SIZE_MB )); then
                    echo "${fsize_mb}MB: $entry"
                fi
            fi
        fi
    done
}

echo "Scanning $ROOT_DIR"
echo "Conditions: Prune folders < ${FOLDER_THRESHOLD_MB}MB, List files >= ${MIN_FILE_SIZE_MB}MB, Max Depth $MAX_DEPTH"
echo "---------------------------------------------------"

scan_dir "$ROOT_DIR" 0
