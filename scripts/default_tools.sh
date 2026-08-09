#!/bin/bash
# Install Superset Default Tools (mirrors platform/superset DEFAULT_TOOLS).
# Works on macOS and Ubuntu/Debian Linux (go install is OS/arch-native).
# Usage: ./scripts/default_tools.sh
set -euo pipefail

source "$(dirname "$0")/settings.sh"

export PATH="${USER_BIN}:${USER_LIB}/go/bin:${PATH}"

# git — go install @master fetches modules via VCS
if ! command -v git >/dev/null 2>&1; then
    echo "prerequisite missing: git — installing"
    if command -v brew >/dev/null 2>&1; then
        brew install git
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y git
    else
        echo "error: cannot install git (need brew or apt-get)" >&2
        exit 1
    fi
fi

go install github.com/bizshuk/pm2@master
go install github.com/bizshuk/skills@master
go install github.com/bizshuk/dux@master
go install github.com/bizshuk/port@master
go install github.com/bizshuk/sessiond@master
go install github.com/bizshuk/autop@master
go install github.com/bizshuk/auth@master
go install github.com/bizshuk/proxy@master
go install github.com/bizshuk/mdserver@master
