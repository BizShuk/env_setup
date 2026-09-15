#!/bin/bash
# node.sh: 清理 Node.js / Bun 快取與專案 node_modules
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_lib_cleanup.sh"

print_help() {
    echo "Usage: $(basename "$0") [--apply] [--yes|-y] [--dry-run|-n] [--help|-h]"
    echo "清理 Node.js/Bun 快取 (npm, bun, _npx) 與專案中的 node_modules。"
    echo ""
    echo "Options:"
    echo "  --apply        執行實際清理 (預設為預覽模式 Preview Mode)"
    echo "  --yes, -y      自動確認，跳過個別確認提示"
    echo "  --dry-run, -n  預覽待清理目標與預估大小 (預設行為)"
    echo "  --help, -h     顯示此說明訊息"
}

parse_cleanup_args "$@"

NPX_DIR="${HOME}/.npm/_npx"
NPM_CACHE_DIR="${HOME}/.npm/_cacache"
PNPM_STORE_DIR="${HOME}/Library/pnpm/store"
[ -d "${PNPM_STORE_DIR}" ] || PNPM_STORE_DIR="${HOME}/.local/share/pnpm/store"
BUN_CACHE_DIR="${HOME}/.bun/install/cache"
PROJECTS_DIR="${USER_PROJECT:-${HOME}/projects}"

# Collect node_modules directories
find_node_modules() {
    if [ -d "${PROJECTS_DIR}" ]; then
        find "${PROJECTS_DIR}" -name "node_modules" -type d -prune 2>/dev/null || true
    fi
}

if [ "${APPLY}" != true ]; then
    print_preview_header "Node.js, pnpm & Bun"
    
    size_npx=$(get_path_size "${NPX_DIR}")
    print_preview_target "${NPX_DIR}" "${size_npx}" "npx temporary packages"

    size_npm=$(get_path_size "${NPM_CACHE_DIR}")
    print_preview_target "${NPM_CACHE_DIR}" "${size_npm}" "npm cache (npm cache clean --force)"

    if command -v pnpm >/dev/null 2>&1 || [ -d "${PNPM_STORE_DIR}" ]; then
        size_pnpm=$(get_path_size "${PNPM_STORE_DIR}")
        print_preview_target "${PNPM_STORE_DIR}" "${size_pnpm}" "pnpm content-addressable store (pnpm store prune)"
    fi

    if command -v bun >/dev/null 2>&1 || [ -d "${BUN_CACHE_DIR}" ]; then
        size_bun=$(get_path_size "${BUN_CACHE_DIR}")
        print_preview_target "${BUN_CACHE_DIR}" "${size_bun}" "Bun package cache (bun pm cache rm)"
    fi

    echo ""
    echo "--- [專案 node_modules 目錄掃描 (${PROJECTS_DIR})] ---"
    nm_count=0
    while IFS= read -r nm_path; do
        [ -z "${nm_path}" ] && continue
        nm_count=$((nm_count + 1))
        nm_size=$(get_path_size "${nm_path}")
        printf "  %-50s %s\n" "${nm_path}" "${nm_size}"
    done < <(find_node_modules)

    if [ "${nm_count}" -eq 0 ]; then
        echo "  未找到任何 node_modules 目錄。"
    else
        echo "  共計找到 ${nm_count} 個 node_modules 目錄。"
    fi

    echo ""
    print_preview_footer
    exit 0
fi

print_apply_header "Node.js & Bun"

if [ -d "${NPX_DIR}" ]; then
    size_npx=$(get_path_size "${NPX_DIR}")
    if confirm_action "npx 暫存目錄 (${NPX_DIR} - ${size_npx})"; then
        clean_path "${NPX_DIR}"
        echo "  ✓ 已清理 npx 暫存目錄"
    fi
fi

if command -v npm >/dev/null 2>&1; then
    size_npm=$(get_path_size "${NPM_CACHE_DIR}")
    if confirm_action "npm 快取 (${size_npm}) (npm cache clean --force)"; then
        npm cache clean --force
        echo "  ✓ 已清理 npm 快取"
    fi
fi

if command -v pnpm >/dev/null 2>&1; then
    size_pnpm=$(get_path_size "${PNPM_STORE_DIR}")
    if confirm_action "pnpm store (${size_pnpm}) (pnpm store prune)"; then
        pnpm store prune
        echo "  ✓ 已清理 pnpm store"
    fi
fi

if command -v bun >/dev/null 2>&1; then
    size_bun=$(get_path_size "${BUN_CACHE_DIR}")
    if confirm_action "Bun 套件快取 (${size_bun}) (bun pm cache rm)"; then
        bun pm cache rm
        echo "  ✓ 已清理 Bun 快取"
    fi
fi

# Clean node_modules
nm_list=()
while IFS= read -r nm_path; do
    [ -n "${nm_path}" ] && nm_list+=("${nm_path}")
done < <(find_node_modules)

if [ "${#nm_list[@]}" -gt 0 ]; then
    if confirm_action "${PROJECTS_DIR} 下所有 node_modules 目錄 (共 ${#nm_list[@]} 個目錄)"; then
        for nm_path in "${nm_list[@]}"; do
            rm -rf "${nm_path}" 2>/dev/null || true
            echo "  ✓ 已刪除: ${nm_path}"
        done
    fi
else
    echo "  - 未找到任何 node_modules 目錄，略過。"
fi

echo ""
echo "完成: Node.js & Bun 清理完畢。"
