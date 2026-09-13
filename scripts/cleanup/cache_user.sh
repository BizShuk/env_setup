#!/bin/bash
# cache_user.sh: 清理使用者層級快取與垃圾桶 (~/.cache, ~/Library/Caches, ~/.Trash)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_lib_cleanup.sh"

print_help() {
    echo "Usage: $(basename "$0") [--apply] [--yes|-y] [--dry-run|-n] [--help|-h]"
    echo "清理使用者層級快取與垃圾桶內容 (~/.cache, ~/Library/Caches, ~/.Trash)。"
    echo ""
    echo "Options:"
    echo "  --apply        執行實際清理 (預設為預覽模式 Preview Mode)"
    echo "  --yes, -y      自動確認，跳過個別確認提示"
    echo "  --dry-run, -n  預覽待清理目標與預估大小 (預設行為)"
    echo "  --help, -h     顯示此說明訊息"
}

parse_cleanup_args "$@"

TARGETS=(
    "${HOME}/.cache"
    "${HOME}/Library/Caches"
    "${HOME}/.Trash"
)

DESCS=(
    "User general cache"
    "macOS User Library Caches"
    "User Trash"
)

if [ "${APPLY}" != true ]; then
    print_preview_header "User Caches & Trash"
    for i in "${!TARGETS[@]}"; do
        target="${TARGETS[$i]}"
        desc="${DESCS[$i]}"
        if [ -d "${target}" ]; then
            size=$(get_path_size "${target}")
            print_preview_target "${target}/*" "${size}" "${desc}"
        else
            print_preview_target "${target}/*" "0 B" "目錄不存在"
        fi
    done
    print_preview_footer
    exit 0
fi

print_apply_header "User Caches & Trash"
cleaned_count=0
skipped_count=0

for i in "${!TARGETS[@]}"; do
    target="${TARGETS[$i]}"
    desc="${DESCS[$i]}"
    if [ ! -d "${target}" ]; then
        echo "  - 目錄不存在，略過: ${target}"
        continue
    fi
    size=$(get_path_size "${target}")
    if confirm_action "${target}/* (${size} - ${desc})"; then
        clean_dir_contents "${target}"
        echo "  ✓ 已清理: ${target}/*"
        cleaned_count=$((cleaned_count + 1))
    else
        skipped_count=$((skipped_count + 1))
    fi
done

echo ""
echo "完成: 已清理 ${cleaned_count} 個項目，跳過 ${skipped_count} 個項目。"
