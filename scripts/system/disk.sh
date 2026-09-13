#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi

OS="${OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

echo "磁碟儲存 (Disk Storage)"

# 1. Root Partition summary (matches Go CLI system disk output)
if df_root=$(df -h / 2>/dev/null | tail -n 1); then
    # shellcheck disable=SC2086
    set -- $df_root
    if [ $# -ge 5 ]; then
        echo "- Root Partition: $2 (Used: $3, Free: $4, Usage: $5)"
    fi
fi

echo ""
echo "掛載點 (Mount Points):"
if [ "$OS" = "darwin" ]; then
    df -h | awk 'NR==1 || ($1 !~ /^(devfs|map)/)'
    echo ""
    echo "磁碟清單 (Disks):"
    if command -v diskutil >/dev/null 2>&1; then
        diskutil list physical 2>/dev/null || diskutil list
    fi
else
    # Linux: filter out tmpfs/devtmpfs if possible
    if df -h -x tmpfs -x devtmpfs -x squashfs >/dev/null 2>&1; then
        df -h -x tmpfs -x devtmpfs -x squashfs
    else
        df -h
    fi
    echo ""
    echo "磁碟清單 (Disks):"
    if command -v lsblk >/dev/null 2>&1; then
        lsblk -e 7 -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT 2>/dev/null || lsblk
    elif command -v fdisk >/dev/null 2>&1; then
        fdisk -l 2>/dev/null || true
    fi
fi
