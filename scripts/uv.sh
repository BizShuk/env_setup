#!/bin/bash
set -euo pipefail

# ============================================================================
# uv.sh — Install Astral uv Python toolchain
# ============================================================================

source "$(dirname "$0")/settings.sh"

if command -v uv >/dev/null 2>&1; then
    echo "uv is already installed: $(command -v uv) ($(uv --version))"
    exit 0
fi

echo "Installing uv (Fast Python package installer)..."
curl -LsSf https://astral.sh/uv/install.sh | sh

echo "uv installed successfully."
