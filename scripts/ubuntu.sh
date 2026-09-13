#!/bin/bash
set -euo pipefail

# ============================================================================
# ubuntu.sh — Ubuntu full bootstrap orchestrator
# ============================================================================
# Sequentially runs the modular Ubuntu setup steps:
#   1. Apt packages (ubuntu_apt.sh)
#   2. Locale configuration (ubuntu_locale.sh)
#   3. Timezone configuration (ubuntu_timezone.sh)
#   4. User setup (ubuntu_user.sh)
#
# Individual steps can also be executed directly or via npm run:ubuntu:*
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/settings.sh"

"${SCRIPT_DIR}/ubuntu_apt.sh"
"${SCRIPT_DIR}/ubuntu_locale.sh"
"${SCRIPT_DIR}/ubuntu_timezone.sh"
"${SCRIPT_DIR}/ubuntu_user.sh"

echo "Ubuntu bootstrap complete."
