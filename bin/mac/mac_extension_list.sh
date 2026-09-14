#!/bin/bash
if [ "$(uname -s)" != "Darwin" ]; then
    echo "Notice: mac_extension_list requires macOS. Skipping."
    exit 0
fi

# SCRIPT_DIR="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"
SCRIPT_DIR=$(dirname "$0")

pushd "$SCRIPT_DIR/mac" || exit

./ls_sys_path.py <sys_path
