#!/bin/bash
# browser.sh: 清理瀏覽器快取與暫存 (Google Chrome, Apple Safari)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_lib_cleanup.sh"

print_help() {
    echo "Usage: $(basename "$0") [--apply] [--yes|-y] [--dry-run|-n] [--help|-h]"
    echo "清理 Google Chrome 與 Apple Safari 的本機快取與暫存目錄："
    echo "  - Chrome Default Cache_Data 與快取目錄"
    echo "  - Chrome macOS 暫存目錄 (.com.google.Chrome.*, code_sign_clone)"
    echo "  - Safari 快取目錄 (com.apple.Safari, Metadata/Safari 等)"
    echo ""
    echo "Options:"
    echo "  --apply        執行實際清理 (預設為預覽模式 Preview Mode)"
    echo "  --yes, -y      自動確認，跳過個別確認提示"
    echo "  --dry-run, -n  預覽待清理目標與預估大小 (預設行為)"
    echo "  --help, -h     顯示此說明訊息"
}

parse_cleanup_args "$@"

LIBRARY="${HOME}/Library"
DARWIN_TEMP=""
if command -v getconf >/dev/null 2>&1; then
    DARWIN_TEMP="$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null || true)"
fi

CHROME_CACHE_DATA="${LIBRARY}/Caches/Google/Chrome/Default/Cache/Cache_Data"
CHROME_CACHE_ROOT="${LIBRARY}/Caches/Google/Chrome"

SAFARI_TARGETS=(
    "${LIBRARY}/Caches/com.apple.Safari"
    "${LIBRARY}/Caches/Metadata/Safari"
    "${LIBRARY}/Caches/Apple - Safari - Safari Extensions Gallery"
    "${LIBRARY}/Caches/com.apple.WebKit.PluginProcess"
)

# Collect Chrome temp dirs
chrome_temp_dirs=()
if [ -n "${DARWIN_TEMP}" ] && [ -d "${DARWIN_TEMP}" ]; then
    while IFS= read -r p; do
        [ -e "${p}" ] && chrome_temp_dirs+=("${p}")
    done < <(compgen -G "${DARWIN_TEMP}/.com.google.Chrome.*" || true)

    code_clone="$(dirname "${DARWIN_TEMP}")/X/com.google.Chrome.code_sign_clone"
    if [ -e "${code_clone}" ]; then
        chrome_temp_dirs+=("${code_clone}")
    fi
fi

if [ "${APPLY}" != true ]; then
    print_preview_header "Browser Caches (Chrome & Safari)"

    # Chrome
    if [ -d "${CHROME_CACHE_DATA}" ]; then
        size=$(get_path_size "${CHROME_CACHE_DATA}")
        print_preview_target "${CHROME_CACHE_DATA}" "${size}" "Chrome Default Cache_Data"
    elif [ -d "${CHROME_CACHE_ROOT}" ]; then
        size=$(get_path_size "${CHROME_CACHE_ROOT}")
        print_preview_target "${CHROME_CACHE_ROOT}" "${size}" "Chrome Cache"
    fi

    for tdir in "${chrome_temp_dirs[@]}"; do
        size=$(get_path_size "${tdir}")
        print_preview_target "${tdir}" "${size}" "Chrome temporary clone/dir"
    done

    # Safari
    for starget in "${SAFARI_TARGETS[@]}"; do
        if [ -e "${starget}" ]; then
            size=$(get_path_size "${starget}")
            print_preview_target "${starget}" "${size}" "Safari cache"
        fi
    done

    print_preview_footer
    exit 0
fi

print_apply_header "Browser Caches (Chrome & Safari)"
cleaned_count=0
skipped_count=0

# Clean Chrome Cache_Data
if [ -d "${CHROME_CACHE_DATA}" ]; then
    size=$(get_path_size "${CHROME_CACHE_DATA}")
    if confirm_action "Chrome Cache_Data (${CHROME_CACHE_DATA} - ${size})"; then
        clean_dir_contents "${CHROME_CACHE_DATA}"
        echo "  ✓ 已清理: Chrome Cache_Data"
        cleaned_count=$((cleaned_count + 1))
    else
        skipped_count=$((skipped_count + 1))
    fi
fi

# Clean Chrome temp dirs
for tdir in "${chrome_temp_dirs[@]}"; do
    [ ! -e "${tdir}" ] && continue
    size=$(get_path_size "${tdir}")
    if confirm_action "Chrome 暫存項目 (${tdir} - ${size})"; then
        clean_path "${tdir}"
        echo "  ✓ 已清理: ${tdir}"
        cleaned_count=$((cleaned_count + 1))
    else
        skipped_count=$((skipped_count + 1))
    fi
done

# Clean Safari caches
for starget in "${SAFARI_TARGETS[@]}"; do
    [ ! -e "${starget}" ] && continue
    size=$(get_path_size "${starget}")
    if confirm_action "Safari 快取項目 (${starget} - ${size})"; then
        clean_path "${starget}"
        echo "  ✓ 已清理: ${starget}"
        cleaned_count=$((cleaned_count + 1))
    else
        skipped_count=$((skipped_count + 1))
    fi
done

echo ""
echo "完成: 已清理 ${cleaned_count} 個項目，跳過 ${skipped_count} 個項目。"
