#!/bin/bash
# all.sh: 聚合執行所有 Cleanup 子元件腳本
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_lib_cleanup.sh"

print_help() {
    echo "Usage: $(basename "$0") [--apply] [--yes|-y] [--dry-run|-n] [--help|-h]"
    echo "依序執行所有清理子元件腳本："
    echo "  1. system_log.sh  - 系統日誌 (/private/var/log, /Library/Logs)"
    echo "  2. system_tmp.sh  - 系統暫存 (/private/var/tmp)"
    echo "  3. cache_user.sh  - 使用者快取 (~/.cache, ~/Library/Caches, ~/.Trash)"
    echo "  4. docker.sh      - Docker 容器、映像與建置快取 prune"
    echo "  5. brew.sh        - Homebrew 快取清理與 bundle 整理"
    echo "  6. node.sh        - npm/bun 快取與專案 node_modules"
    echo "  7. python.sh      - pip/uv 快取與專案 venv"
    echo "  8. go.sh          - Go 建置快取與 workspace source"
    echo "  9. ai.sh          - Claude/Codex/Gemini 過期 sessions 與暫存"
    echo " 10. browser.sh     - Chrome 與 Safari 快取與暫存"
    echo " 11. app.sh         - Lark、Podcasts 與 iOS 備份/更新"
    echo ""
    echo "Options:"
    echo "  --apply        執行實際清理 (預設為預覽模式 Preview Mode)"
    echo "  --yes, -y      自動確認，跳過個別確認提示"
    echo "  --dry-run, -n  預覽所有子元件之待清理目標與預估大小 (預設行為)"
    echo "  --help, -h     顯示此說明訊息"
}

# Check for help flag before processing
for arg in "$@"; do
    case "${arg}" in
        --help|-h)
            print_help
            exit 0
            ;;
    esac
done

SUB_SCRIPTS=(
    "system_log.sh"
    "system_tmp.sh"
    "cache_user.sh"
    "docker.sh"
    "brew.sh"
    "node.sh"
    "python.sh"
    "go.sh"
    "ai.sh"
    "browser.sh"
    "app.sh"
)

mode="Preview Mode (Dry-run)"
for arg in "$@"; do
    if [ "${arg}" = "--apply" ]; then
        mode="Apply Mode"
        break
    fi
done

echo "=================================================================="
echo " Cleanup All: 開始執行清理流程 [${mode}]"
echo "=================================================================="
echo ""

failed_scripts=()
success_count=0

for sub in "${SUB_SCRIPTS[@]}"; do
    sub_path="${SCRIPT_DIR}/${sub}"
    if [ ! -f "${sub_path}" ]; then
        echo "警告: 子腳本不存在: ${sub_path}" >&2
        failed_scripts+=("${sub}")
        continue
    fi

    echo ">>> [${sub}] 執行中..."
    if /bin/bash "${sub_path}" "$@"; then
        success_count=$((success_count + 1))
    else
        echo "警告: 子腳本執行失敗: ${sub}" >&2
        failed_scripts+=("${sub}")
    fi
    echo ""
done

echo "=================================================================="
echo " Cleanup All 執行摘要"
echo "=================================================================="
echo "成功完成: ${success_count} / ${#SUB_SCRIPTS[@]} 個子元件"
if [ "${#failed_scripts[@]}" -gt 0 ]; then
    echo "失敗項目: ${failed_scripts[*]}" >&2
    exit 1
fi
echo "全部子元件順利完成。"
