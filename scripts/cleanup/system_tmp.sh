#!/bin/bash
# system_tmp.sh: 清理系統暫存目錄內容 (/private/var/tmp)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_lib_cleanup.sh"

print_help() {
    echo "Usage: $(basename "$0") [--apply] [--yes|-y] [--dry-run|-n] [--help|-h]"
    echo "高風險：清理系統暫存目錄內容 (/private/var/tmp)。"
    echo ""
    echo "Options:"
    echo "  --apply        執行實際清理 (預設為預覽模式 Preview Mode)"
    echo "  --yes, -y      自動確認，跳過個別確認提示"
    echo "  --dry-run, -n  預覽待清理目標與預估大小 (預設行為)"
    echo "  --help, -h     顯示此說明訊息"
}

parse_cleanup_args "$@"
check_root_required "清理系統暫存"

TARGET="/private/var/tmp"

if [ "${APPLY}" != true ]; then
    print_preview_header "System Temporary"
    if [ -d "${TARGET}" ]; then
        size=$(get_path_size "${TARGET}")
        print_preview_target "${TARGET}/*" "${size}" "System temporary contents"
    else
        print_preview_target "${TARGET}/*" "0 B" "目錄不存在"
    fi
    print_preview_footer
    exit 0
fi

print_apply_header "System Temporary"
if [ ! -d "${TARGET}" ]; then
    echo "  - 目錄不存在，略過: ${TARGET}"
    exit 0
fi

size=$(get_path_size "${TARGET}")
if confirm_action "${TARGET}/* (${size})"; then
    clean_dir_contents "${TARGET}" "${SUDO:-}"
    echo "  ✓ 已清理: ${TARGET}/*"
else
    echo "  - 已跳過清理。"
fi
