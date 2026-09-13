#!/bin/bash
# app.sh: 清理常見應用程式快取與暫存 (Lark, Apple Podcasts, iOS Updates/Backups)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_lib_cleanup.sh"

print_help() {
    echo "Usage: $(basename "$0") [--apply] [--yes|-y] [--dry-run|-n] [--help|-h]"
    echo "清理常見應用程式本機快取、日誌與暫存："
    echo "  - Lark (Feishu/LarkInternational) 日誌、更新檔與 Shader 快取"
    echo "  - Apple Podcasts 串流快取 (StreamedMedia *.mp3)"
    echo "  - iOS 裝置備份與軟體更新檔 (MobileSync/Backup, iPhone Software Updates)"
    echo ""
    echo "Options:"
    echo "  --apply        執行實際清理 (預設為預覽模式 Preview Mode)"
    echo "  --yes, -y      自動確認，跳過個別確認提示"
    echo "  --dry-run, -n  預覽待清理目標與預估大小 (預設行為)"
    echo "  --help, -h     顯示此說明訊息"
}

parse_cleanup_args "$@"

LIBRARY="${HOME}/Library"
LARK_DIR="${LIBRARY}/Application Support/LarkInternational"
PODCASTS_DIR="${LIBRARY}/Containers/com.apple.podcasts/Data/tmp/StreamedMedia"
IOS_UPDATES_DIR="${LIBRARY}/iTunes/iPhone Software Updates"
IOS_BACKUP_DIR="${LIBRARY}/Application Support/MobileSync/Backup"

TARGETS=()
DESCS=()

# Collect Lark targets if Lark directory exists
if [ -d "${LARK_DIR}" ]; then
    TARGETS+=(
        "${LARK_DIR}/sdk_storage/log"
        "${LARK_DIR}/update"
        "${LARK_DIR}/ShaderCache"
        "${LARK_DIR}/CodeCache"
    )
    DESCS+=(
        "Lark logs & crash dumps"
        "Lark update packages"
        "Lark ShaderCache"
        "Lark CodeCache"
    )
fi

# Podcasts StreamedMedia
TARGETS+=("${PODCASTS_DIR}")
DESCS+=("Apple Podcasts streamed media cache")

# iOS Software Updates & Backups
TARGETS+=(
    "${IOS_UPDATES_DIR}"
    "${IOS_BACKUP_DIR}"
)
DESCS+=(
    "iOS software update downloads"
    "iOS device backups (MobileSync)"
)

if [ "${APPLY}" != true ]; then
    print_preview_header "Applications (Lark, Podcasts, iOS)"
    for i in "${!TARGETS[@]}"; do
        target="${TARGETS[$i]}"
        desc="${DESCS[$i]}"
        if [ -e "${target}" ]; then
            size=$(get_path_size "${target}")
            print_preview_target "${target}" "${size}" "${desc}"
        else
            print_preview_target "${target}" "0 B" "${desc} (未找到)"
        fi
    done
    print_preview_footer
    exit 0
fi

print_apply_header "Applications (Lark, Podcasts, iOS)"
cleaned_count=0
skipped_count=0

for i in "${!TARGETS[@]}"; do
    target="${TARGETS[$i]}"
    desc="${DESCS[$i]}"

    if [ ! -e "${target}" ]; then
        echo "  - 目錄或檔案不存在，略過: ${target}"
        continue
    fi

    size=$(get_path_size "${target}")
    if confirm_action "${desc} (${target} - ${size})"; then
        if [ -d "${target}" ]; then
            clean_dir_contents "${target}"
        else
            clean_path "${target}"
        fi
        echo "  ✓ 已清理: ${target}"
        cleaned_count=$((cleaned_count + 1))
    else
        skipped_count=$((skipped_count + 1))
    fi
done

echo ""
echo "完成: 已清理 ${cleaned_count} 個項目，跳過 ${skipped_count} 個項目。"
