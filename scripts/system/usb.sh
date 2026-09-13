#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi

OS="${OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

echo "USB 裝置 (USB Devices)"

if [ "$OS" = "darwin" ]; then
    profiler_out=$(system_profiler SPUSBDataType 2>/dev/null || true)
    count=0

    if [ -n "$profiler_out" ]; then
        while read -r dev; do
            [ -z "$dev" ] && continue
            echo "- ${dev}"
            count=$(( count + 1 ))
        done < <(echo "$profiler_out" | awk '
        NF > 0 {
            if ($0 ~ /Product ID:/) {
                sub(/:$/, "", prev)
                sub(/^[[:space:]]*/, "", prev)
                if (prev != "") print prev
            }
            prev = $0
        }')
    fi

    if [ "$count" -eq 0 ]; then
        echo "未偵測到外接 USB 裝置 (No external USB devices detected)"
    fi
else
    count=0
    if command -v lsusb >/dev/null 2>&1; then
        while read -r line; do
            [ -z "$line" ] && continue
            # Extract device name after the ID field: Bus 001 Device 002: ID xxxx:yyyy Device Name
            dev_desc=$(echo "$line" | sed -E 's/^Bus [0-9]+ Device [0-9]+: ID [0-9a-fA-F:]+[[:space:]]*//')
            if [ -n "$dev_desc" ]; then
                echo "- ${dev_desc}"
                count=$(( count + 1 ))
            fi
        done < <(lsusb 2>/dev/null || true)
    fi

    if [ "$count" -eq 0 ]; then
        echo "未偵測到 USB 裝置 (No USB devices detected)"
    fi
fi
