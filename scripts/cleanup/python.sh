#!/bin/bash
# python.sh: 清理 Python pip 快取、uv 快取與虛擬環境 (venv)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_lib_cleanup.sh"

print_help() {
    echo "Usage: $(basename "$0") [--apply] [--yes|-y] [--dry-run|-n] [--help|-h]"
    echo "清理 Python 快取 (pip cache purge, uv cache) 與專案中的虛擬環境 (venv dirs)。"
    echo ""
    echo "Options:"
    echo "  --apply        執行實際清理 (預設為預覽模式 Preview Mode)"
    echo "  --yes, -y      自動確認，跳過個別確認提示"
    echo "  --dry-run, -n  預覽待清理目標與預估大小 (預設行為)"
    echo "  --help, -h     顯示此說明訊息"
}

parse_cleanup_args "$@"

PIP_CACHE_MAC="${HOME}/Library/Caches/pip"
PIP_CACHE_LINUX="${HOME}/.cache/pip"
UV_CACHE_DIR="${HOME}/.cache/uv"
PROJECTS_DIR="${USER_PROJECT:-${HOME}/projects}"

# Determine PIP cache dir
PIP_CACHE_DIR="${PIP_CACHE_MAC}"
if [ ! -d "${PIP_CACHE_DIR}" ] && [ -d "${PIP_CACHE_LINUX}" ]; then
    PIP_CACHE_DIR="${PIP_CACHE_LINUX}"
fi

# Find venv directories within projects
find_venv_dirs() {
    if [ -d "${PROJECTS_DIR}" ]; then
        find "${PROJECTS_DIR}" -name "*venv*" -type d -prune 2>/dev/null || true
    fi
}

if [ "${APPLY}" != true ]; then
    print_preview_header "Python & uv"
    
    size_pip=$(get_path_size "${PIP_CACHE_DIR}")
    print_preview_target "${PIP_CACHE_DIR}" "${size_pip}" "pip cache (pip cache purge)"

    size_uv=$(get_path_size "${UV_CACHE_DIR}")
    print_preview_target "${UV_CACHE_DIR}" "${size_uv}" "uv cache (~/.cache/uv)"

    echo ""
    echo "--- [專案虛擬環境目錄掃描 (${PROJECTS_DIR})] ---"
    venv_count=0
    while IFS= read -r venv_path; do
        [ -z "${venv_path}" ] && continue
        venv_count=$((venv_count + 1))
        venv_size=$(get_path_size "${venv_path}")
        printf "  %-50s %s\n" "${venv_path}" "${venv_size}"
    done < <(find_venv_dirs)

    if [ "${venv_count}" -eq 0 ]; then
        echo "  未找到任何虛擬環境目錄。"
    else
        echo "  共計找到 ${venv_count} 個虛擬環境目錄。"
    fi

    echo ""
    print_preview_footer
    exit 0
fi

print_apply_header "Python & uv"

# Clean pip cache
pip_cmd=""
if command -v pip >/dev/null 2>&1; then
    pip_cmd="pip"
elif command -v pip3 >/dev/null 2>&1; then
    pip_cmd="pip3"
fi

if [ -n "${pip_cmd}" ]; then
    size_pip=$(get_path_size "${PIP_CACHE_DIR}")
    if confirm_action "pip 快取 (${size_pip}) (${pip_cmd} cache purge)"; then
        "${pip_cmd}" cache purge || true
        echo "  ✓ 已清理 pip 快取"
    fi
elif [ -d "${PIP_CACHE_DIR}" ]; then
    size_pip=$(get_path_size "${PIP_CACHE_DIR}")
    if confirm_action "pip 快取目錄 (${PIP_CACHE_DIR} - ${size_pip})"; then
        clean_dir_contents "${PIP_CACHE_DIR}"
        echo "  ✓ 已清理 pip 快取目錄"
    fi
fi

# Clean uv cache
if command -v uv >/dev/null 2>&1; then
    size_uv=$(get_path_size "${UV_CACHE_DIR}")
    if confirm_action "uv 快取 (${size_uv}) (uv cache clean)"; then
        uv cache clean || true
        echo "  ✓ 已清理 uv 快取"
    fi
elif [ -d "${UV_CACHE_DIR}" ]; then
    size_uv=$(get_path_size "${UV_CACHE_DIR}")
    if confirm_action "uv 快取目錄 (${UV_CACHE_DIR} - ${size_uv})"; then
        clean_path "${UV_CACHE_DIR}"
        echo "  ✓ 已清理 uv 快取目錄"
    fi
fi

# Clean venv dirs
venv_list=()
while IFS= read -r venv_path; do
    [ -n "${venv_path}" ] && venv_list+=("${venv_path}")
done < <(find_venv_dirs)

if [ "${#venv_list[@]}" -gt 0 ]; then
    if confirm_action "${PROJECTS_DIR} 下所有虛擬環境目錄 (共 ${#venv_list[@]} 個目錄)"; then
        for venv_path in "${venv_list[@]}"; do
            rm -rf "${venv_path}" 2>/dev/null || true
            echo "  ✓ 已刪除: ${venv_path}"
        done
    fi
else
    echo "  - 未找到任何虛擬環境目錄，略過。"
fi

echo ""
echo "完成: Python & uv 清理完畢。"
