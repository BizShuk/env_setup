#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi

OS="${OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

echo "記憶體 (Memory)"

if [ "$OS" = "darwin" ]; then
    total_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
    total_gb=$(( total_bytes / 1073741824 ))

    # Calculate free and used using vm_stat
    vm_stat_out=$(vm_stat 2>/dev/null || true)
    page_size=$(echo "$vm_stat_out" | awk '/page size of/ {print $8}' || echo "16384")
    if [ -z "$page_size" ]; then page_size=16384; fi

    free_pages=$(echo "$vm_stat_out" | awk '/Pages free:/ {print $3}' | tr -d '.' || echo "0")
    spec_pages=$(echo "$vm_stat_out" | awk '/Pages speculative:/ {print $3}' | tr -d '.' || echo "0")

    free_pages=${free_pages:-0}
    spec_pages=${spec_pages:-0}

    free_bytes=$(( (free_pages + spec_pages) * page_size ))
    if [ "$free_bytes" -gt "$total_bytes" ]; then
        free_bytes=0
    fi
    used_bytes=$(( total_bytes - free_bytes ))

    used_gb=$(awk "BEGIN {printf \"%.1f\", ${used_bytes} / 1073741824}")
    free_gb=$(awk "BEGIN {printf \"%.1f\", ${free_bytes} / 1073741824}")

    if [ "$total_bytes" -gt 0 ]; then
        used_pct=$(awk "BEGIN {printf \"%.0f\", (${used_bytes} / ${total_bytes}) * 100}")
        free_pct=$(( 100 - used_pct ))
    else
        used_pct=0
        free_pct=0
    fi

    echo "- Total RAM: ${total_gb} GB"
    echo "- Used RAM: ${used_gb} GB (${used_pct}%)"
    echo "- Free RAM: ${free_gb} GB (${free_pct}%)"

    swap_info=$(sysctl -n vm.swapusage 2>/dev/null || true)
    if [ -n "$swap_info" ]; then
        echo "- Swap: ${swap_info}"
    fi
else
    if [ -f /proc/meminfo ]; then
        mem_total_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo || echo "0")
        mem_free_kb=$(awk '/MemFree:/ {print $2}' /proc/meminfo || echo "0")
        mem_avail_kb=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo || echo "0")
        swap_total_kb=$(awk '/SwapTotal:/ {print $2}' /proc/meminfo || echo "0")
        swap_free_kb=$(awk '/SwapFree:/ {print $2}' /proc/meminfo || echo "0")

        total_gb=$(awk "BEGIN {printf \"%.1f\", ${mem_total_kb} / 1048576}")
        if [ "$mem_avail_kb" -gt 0 ] 2>/dev/null; then
            avail_kb=$mem_avail_kb
        else
            avail_kb=$mem_free_kb
        fi
        free_gb=$(awk "BEGIN {printf \"%.1f\", ${avail_kb} / 1048576}")
        used_kb=$(( mem_total_kb - avail_kb ))
        used_gb=$(awk "BEGIN {printf \"%.1f\", ${used_kb} / 1048576}")

        if [ "$mem_total_kb" -gt 0 ]; then
            used_pct=$(awk "BEGIN {printf \"%.0f\", (${used_kb} / ${mem_total_kb}) * 100}")
            free_pct=$(( 100 - used_pct ))
        else
            used_pct=0
            free_pct=0
        fi

        echo "- Total RAM: ${total_gb} GB"
        echo "- Used RAM: ${used_gb} GB (${used_pct}%)"
        echo "- Free RAM: ${free_gb} GB (${free_pct}%)"

        if [ "$swap_total_kb" -gt 0 ]; then
            swap_used_kb=$(( swap_total_kb - swap_free_kb ))
            swap_total_mb=$(( swap_total_kb / 1024 ))
            swap_used_mb=$(( swap_used_kb / 1024 ))
            echo "- Swap: total = ${swap_total_mb} MB, used = ${swap_used_mb} MB"
        fi
    elif command -v free >/dev/null 2>&1; then
        free -h
    else
        echo "Unable to determine memory statistics."
    fi
fi
