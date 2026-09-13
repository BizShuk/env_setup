#!/bin/bash
set -euo pipefail

# ============================================================================
# nodejs.sh — Node.js full bootstrap orchestrator
# ============================================================================
# Sequentially runs the modular Node.js setup steps:
#   1. NVM + Node runtime (nodejs_nvm.sh)
#   2. pnpm package manager + global packages (pnpm.sh)
#
# Individual steps can also be executed directly or via npm run:nodejs:*
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/settings.sh"

"${SCRIPT_DIR}/nodejs_nvm.sh"
"${SCRIPT_DIR}/pnpm.sh"

echo "Node.js bootstrap complete."
