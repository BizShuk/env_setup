#!/bin/bash
set -euo pipefail

# ============================================================================
# ubuntu_user.sh — Add user and group on Ubuntu if not present
# ============================================================================

source "$(dirname "$0")/settings.sh"

if ! id -u "$user" &>/dev/null; then
    sudo useradd "$user" -m -s /bin/bash
    sudo passwd "$user"
fi

if ! getent group "$user" &>/dev/null; then
    sudo groupadd "$user"
fi
