#!/bin/bash
# brew.sh: 清理 Homebrew cache 與未追蹤套件
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_lib_cleanup.sh"

print_help() {
    echo "Usage: $(basename "$0") [--apply] [--yes|-y] [--dry-run|-n] [--help|-h]"
    echo "清理 Homebrew 下載快取 (brew cleanup) 與未在 Brewfile 宣告的套件 (brew bundle cleanup)。"
    echo ""
    echo "Options:"
    echo "  --apply        執行實際清理 (預設為預覽模式 Preview Mode)"
    echo "  --yes, -y      自動確認，跳過個別確認提示"
    echo "  --dry-run, -n  預覽待清理目標與預估大小 (預設行為)"
    echo "  --help, -h     顯示此說明訊息"
}

parse_cleanup_args "$@"

if ! command -v brew >/dev/null 2>&1; then
    echo "提示: 系統未安裝 brew，略過 Homebrew 清理。"
    exit 0
fi

BREW_CACHE_DIR="$(brew --cache 2>/dev/null || echo "${HOME}/Library/Caches/Homebrew")"
BREWFILE="${REPO_DIR}/scripts/Brewfile"

if [ "${APPLY}" != true ]; then
    print_preview_header "Homebrew"
    size=$(get_path_size "${BREW_CACHE_DIR}")
    print_preview_target "${BREW_CACHE_DIR}" "${size}" "Homebrew cache directory"
    
    echo ""
    echo "--- [brew cleanup --prune=all 乾跑預覽] ---"
    brew cleanup -n --prune=all 2>/dev/null || echo "無可清理之舊版套件或快取。"

    if [ -f "${BREWFILE}" ]; then
        echo ""
        echo "--- [brew bundle cleanup 乾跑預覽 (比對 ${BREWFILE})] ---"
        brew bundle cleanup --file="${BREWFILE}" 2>/dev/null || echo "無未追蹤之 Homebrew 套件。"
    fi

    echo ""
    print_preview_footer
    exit 0
fi

print_apply_header "Homebrew"

cache_size=$(get_path_size "${BREW_CACHE_DIR}")
if confirm_action "Homebrew 下載與安裝快取 (${cache_size}) (brew cleanup --prune=all)"; then
    brew cleanup --prune=all
    echo "  ✓ 已清理 Homebrew 快取"
fi

if [ -f "${BREWFILE}" ]; then
    if confirm_action "未在 Brewfile 宣告之 Homebrew 套件 (brew bundle cleanup --force)"; then
        brew bundle cleanup --file="${BREWFILE}" --force
        echo "  ✓ 已清理未宣告之套件"
    fi
else
    echo "  - 未找到 Brewfile (${BREWFILE})，略過 bundle cleanup。"
fi

echo ""
echo "完成: Homebrew 清理完畢。"
