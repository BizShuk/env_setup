#!/bin/bash
# ai.sh: 清理 AI 輔助工具 (Claude, Codex, Gemini) 之過期暫存與 sessions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_lib_cleanup.sh"

print_help() {
    echo "Usage: $(basename "$0") [--apply] [--yes|-y] [--dry-run|-n] [--help|-h]"
    echo "清理 AI 輔助工具過期歷史紀錄與暫存檔："
    echo "  - ~/.claude/projects (>60 天)"
    echo "  - ~/.codex/sessions (>60 天)"
    echo "  - ~/.codex/generated_images (>30 天)"
    echo "  - ~/.gemini/tmp (>30 天)"
    echo ""
    echo "Options:"
    echo "  --apply        執行實際清理 (預設為預覽模式 Preview Mode)"
    echo "  --yes, -y      自動確認，跳過個別確認提示"
    echo "  --dry-run, -n  預覽待清理目標與預估大小 (預設行為)"
    echo "  --help, -h     顯示此說明訊息"
}

parse_cleanup_args "$@"

TARGETS=(
    "${HOME}/.claude/projects"
    "${HOME}/.codex/sessions"
    "${HOME}/.codex/generated_images"
    "${HOME}/.gemini/tmp"
)

DAYS=(
    60
    60
    30
    30
)

DESCS=(
    "Claude project session files (>60d)"
    "Codex session files (>60d)"
    "Codex generated images (>30d)"
    "Gemini temporary files (>30d)"
)

if [ "${APPLY}" != true ]; then
    print_preview_header "AI Assistant Caches"
    for i in "${!TARGETS[@]}"; do
        target="${TARGETS[$i]}"
        day="${DAYS[$i]}"
        desc="${DESCS[$i]}"
        summary=$(get_files_older_than_summary "${target}" "${day}")
        print_preview_target "${target}" "${summary}" "${desc}"
    done
    print_preview_footer
    exit 0
fi

print_apply_header "AI Assistant Caches"
cleaned_count=0
skipped_count=0

for i in "${!TARGETS[@]}"; do
    target="${TARGETS[$i]}"
    day="${DAYS[$i]}"
    desc="${DESCS[$i]}"

    if [ ! -d "${target}" ]; then
        echo "  - 目錄不存在，略過: ${target}"
        continue
    fi

    summary=$(get_files_older_than_summary "${target}" "${day}")
    if [[ "${summary}" =~ ^0[[:space:]]files ]]; then
        echo "  - 無超過 ${day} 天之檔案，略過: ${target}"
        continue
    fi

    if confirm_action "${desc} (${summary})"; then
        delete_files_older_than "${target}" "${day}"
        echo "  ✓ 已清理: ${target} (>${day}d)"
        cleaned_count=$((cleaned_count + 1))
    else
        skipped_count=$((skipped_count + 1))
    fi
done

echo ""
echo "完成: 已清理 ${cleaned_count} 個項目，跳過 ${skipped_count} 個項目。"
