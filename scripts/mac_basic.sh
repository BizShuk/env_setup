#!/bin/bash
set -euo pipefail

# ============================================================================
# mac_basic.sh — Install basic CLI tools (curl, wget, jq) on macOS
# ============================================================================

source "$(dirname "$0")/settings.sh"
# shellcheck source=./_lib_bash_plugin.sh
source "$(dirname "$0")/_lib_bash_plugin.sh"

if ! command -v brew >/dev/null 2>&1; then
    echo "ERROR: Homebrew is required for mac_basic.sh. Run ./scripts/brew.sh first." >&2
    exit 1
fi

echo "Installing basic CLI utilities (curl, wget, jq)..."
brew install curl wget jq

update_bash_plugin_block "curl" \
    '/^# \[curl\]$/d' \
    '/^export PATH=.*\/curl\/bin/d' <<EOF
export PATH="$(brew --prefix curl)/bin:\${PATH}"
EOF

echo "Basic CLI utilities installed successfully."
