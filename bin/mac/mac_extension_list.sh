#!/bin/bash

# SCRIPT_DIR="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"
SCRIPT_DIR=$(dirname "$0")

pushd "$SCRIPT_DIR/mac" || exit

./ls_sys_path.py <sys_path
