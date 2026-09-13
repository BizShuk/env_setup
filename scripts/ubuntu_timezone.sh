#!/bin/bash
set -euo pipefail

# ============================================================================
# ubuntu_timezone.sh — Set timezone on Ubuntu to Asia/Taipei
# ============================================================================

source "$(dirname "$0")/settings.sh"

sudo cp /usr/share/zoneinfo/Asia/Taipei /etc/localtime
