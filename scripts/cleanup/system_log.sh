#!/bin/bash
# system_log.sh: 清理 macOS / Linux 系統日誌內容 (/private/var/log, /Library/Logs)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_lib_cleanup.sh"

print_help() {
    echo "Usage: $(basename "$0") [--apply] [--yes|-y] [--dry-run|-n] [--help|-h]"
    echo "清理系統日誌內容 (/private/var/log 與 /Library/Logs)。"
    echo ""
    echo "Options:"
    echo "  --apply        執行實際清理 (預設為預覽模式 Preview Mode)"
    echo "  --yes, -y      自動確認，跳過個別確認提示"
    echo "  --dry-run, -n  預覽待清理目標與預估大小 (預設行為)"
    echo "  --help, -h     顯示此說明訊息"
}

parse_cleanup_args "$@"
check_root_required "清理系統日誌"

TARGETS=(
    "/private/var/log"
    "/Library/Logs"
)

if [ "${APPLY}" != true ]; then
    print_preview_header "System Logs"
    for target in "${TARGETS[@]}"; do
        if [ -d "${target}" ]; then
            size=$(get_path_size "${target}")
            print_preview_target "${target}/*" "${size}" "System logs content"
        else
            print_preview_target "${target}/*" "0 B" "目錄不存在"
        fi
    done
    print_preview_footer
    exit 0
fi

print_apply_header "System Logs"
cleaned_count=0
skipped_count=0

for target in "${TARGETS[@]}"; do
    if [ ! -d "${target}" ]; then
        echo "  - 目錄不存在，略過: ${target}"
        continue
    fi
    size=$(get_path_size "${target}")
    if confirm_action "${target}/* (${size})"; then
        clean_dir_contents "${target}" "${SUDO:-}"
        echo "  ✓ 已清理: ${target}/*"
        cleaned_count=$((cleaned_count + 1))
    else
        skipped_count=$((skipped_count + 1))
    fi
done

echo ""
echo "完成: 已清理 ${cleaned_count} 個項目，跳過 ${skipped_count} 個項目。"
