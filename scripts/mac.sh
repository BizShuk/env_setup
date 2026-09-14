#!/bin/bash
set -euo pipefail

# ============================================================================
# mac.sh — macOS full bootstrap orchestrator
# ============================================================================
# Sequentially runs the modular macOS setup steps:
#   1. Dotfiles (bash_env_setup.sh)
#   2. Package manager (brew.sh)
#   3. Basic utilities (mac_basic.sh: curl, wget, jq)
#   4. Go toolchain (go.sh)
#   5. uv Python toolchain (uv.sh)
#
# Individual steps can also be executed directly or via npm run:mac:*
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/settings.sh"

if [ "$(uname -s)" != "Darwin" ]; then
    echo "Notice: mac.sh is intended for macOS only (current: $(uname -s)). Skipping."
    exit 0
fi

# 1. Dotfiles environment
"${SCRIPT_DIR}/bash_env_setup.sh"

# 2. Package manager
"${SCRIPT_DIR}/brew.sh"

# 3. Basic utilities (curl, wget, jq)
"${SCRIPT_DIR}/mac_basic.sh"

# 4. Toolchains
"${SCRIPT_DIR}/go.sh"
"${SCRIPT_DIR}/uv.sh"

echo "macOS bootstrap complete."
