#!/bin/bash
# go.sh: 清理 Go 建置快取與 workspace source
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_lib_cleanup.sh"

print_help() {
    echo "Usage: $(basename "$0") [--apply] [--yes|-y] [--dry-run|-n] [--help|-h]"
    echo "清理 Go 建置快取 (go clean -cache) 與 legacy workspace source (projects/.local/go/src)。"
    echo ""
    echo "Options:"
    echo "  --apply        執行實際清理 (預設為預覽模式 Preview Mode)"
    echo "  --yes, -y      自動確認，跳過個別確認提示"
    echo "  --dry-run, -n  預覽待清理目標與預估大小 (預設行為)"
    echo "  --help, -h     顯示此說明訊息"
}

parse_cleanup_args "$@"

GOCACHE_DIR=""
if command -v go >/dev/null 2>&1; then
    GOCACHE_DIR="$(go env GOCACHE 2>/dev/null || true)"
fi
if [ -z "${GOCACHE_DIR}" ]; then
    GOCACHE_DIR="${HOME}/Library/Caches/go-build"
fi

PROJECTS_DIR="${USER_PROJECT:-${HOME}/projects}"
GO_SRC_DIR="${PROJECTS_DIR}/.local/go/src"

if [ "${APPLY}" != true ]; then
    print_preview_header "Go"
    
    size_cache=$(get_path_size "${GOCACHE_DIR}")
    print_preview_target "${GOCACHE_DIR}" "${size_cache}" "Go build cache (go clean -cache)"

    size_src=$(get_path_size "${GO_SRC_DIR}")
    print_preview_target "${GO_SRC_DIR}" "${size_src}" "Legacy Go workspace source"

    echo ""
    print_preview_footer
    exit 0
fi

print_apply_header "Go"

if command -v go >/dev/null 2>&1; then
    size_cache=$(get_path_size "${GOCACHE_DIR}")
    if confirm_action "Go 建置快取 (${GOCACHE_DIR} - ${size_cache}) (go clean -cache)"; then
        go clean -cache
        echo "  ✓ 已清理 Go 建置快取"
    fi
elif [ -d "${GOCACHE_DIR}" ]; then
    size_cache=$(get_path_size "${GOCACHE_DIR}")
    if confirm_action "Go 快取目錄 (${GOCACHE_DIR} - ${size_cache})"; then
        clean_dir_contents "${GOCACHE_DIR}"
        echo "  ✓ 已清理 Go 快取目錄"
    fi
fi

if [ -d "${GO_SRC_DIR}" ]; then
    size_src=$(get_path_size "${GO_SRC_DIR}")
    if confirm_action "Go workspace source (${GO_SRC_DIR} - ${size_src})"; then
        clean_dir_contents "${GO_SRC_DIR}"
        echo "  ✓ 已清理 Go workspace source 內容"
    fi
else
    echo "  - 未找到 ${GO_SRC_DIR} 目錄，略過。"
fi

echo ""
echo "完成: Go 清理完畢。"
