#!/bin/bash
# _lib_cleanup.sh: Cleanup domain scripts shared helper library
# Note: Non-executable helper script intended to be sourced.

set -euo pipefail

# Initialize base environment and settings
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${LIB_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi
REPO_DIR="$(cd "${LIB_DIR}/../.." && pwd)"

APPLY=false
YES=false
SUDO=""

# Parse standard cleanup flags
parse_cleanup_args() {
    APPLY=false
    YES=false
    while [ $# -gt 0 ]; do
        case "$1" in
            --apply)
                APPLY=true
                shift
                ;;
            --yes|-y)
                YES=true
                shift
                ;;
            --dry-run|-n)
                APPLY=false
                shift
                ;;
            --help|-h)
                if type print_help >/dev/null 2>&1; then
                    print_help
                else
                    echo "Usage: $(basename "$0") [--apply] [--yes|-y] [--dry-run|-n] [--help|-h]"
                fi
                exit 0
                ;;
            *)
                echo "Error: unknown argument '$1'" >&2
                if type print_help >/dev/null 2>&1; then
                    print_help >&2
                fi
                exit 1
                ;;
        esac
    done
}

# Root privilege validation
check_root_required() {
    local op="${1:-此操作}"
    SUDO=""
    if [ "$(id -u)" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            export SUDO="sudo"
            if [ "${APPLY}" = true ]; then
                if ! sudo -n true 2>/dev/null; then
                    echo "提示: ${op} 需要 root 權限。若未以 sudo 執行或未快取密碼，清理時可能會提示輸入密碼。"
                fi
            fi
        else
            if [ "${APPLY}" = true ]; then
                echo "警告: ${op} 需要 root 權限，但系統找不到 sudo 指令。" >&2
            fi
        fi
    fi
}

# Get formatted size of a single path
get_path_size() {
    local target="$1"
    if [ ! -e "${target}" ]; then
        echo "0 B (not found)"
        return 0
    fi
    local size
    size=$(du -sh "${target}" 2>/dev/null | awk '{print $1}' || true)
    if [ -z "${size}" ]; then
        echo "N/A (permission restricted)"
    else
        echo "${size}"
    fi
}

# Get summary (file count + total size) of files older than specified days
get_files_older_than_summary() {
    local dir="$1"
    local days="$2"
    if [ ! -d "${dir}" ]; then
        echo "0 files (not found)"
        return 0
    fi
    local count
    count=$(find "${dir}" -type f -mtime +"${days}" 2>/dev/null | wc -l | tr -d ' ')
    if [ -z "${count}" ] || [ "${count}" -eq 0 ]; then
        echo "0 files (0 B)"
        return 0
    fi
    local size
    size=$(find "${dir}" -type f -mtime +"${days}" -exec du -sk {} + 2>/dev/null | awk '{s+=$1} END {if (s>1048576) printf "%.1f GiB", s/1048576; else if (s>1024) printf "%.1f MiB", s/1024; else printf "%d KiB", s}' || true)
    if [ -z "${size}" ]; then
        size="N/A"
    fi
    echo "${count} files (${size})"
}

# Delete files older than specified days
delete_files_older_than() {
    local dir="$1"
    local days="$2"
    if [ ! -d "${dir}" ]; then
        return 0
    fi
    find "${dir}" -type f -mtime +"${days}" -delete 2>/dev/null || true
}

# Safely clean all direct children of a directory (preserving the directory itself)
clean_dir_contents() {
    local dir="$1"
    local sudo_cmd="${2:-}"
    if [ ! -d "${dir}" ]; then
        return 0
    fi
    if [ -n "${sudo_cmd}" ]; then
        find "${dir}" -mindepth 1 -maxdepth 1 -exec "${sudo_cmd}" rm -rf {} + 2>/dev/null || true
    else
        find "${dir}" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
    fi
}

# Safely clean a target path (file or directory)
clean_path() {
    local target="$1"
    local sudo_cmd="${2:-}"
    if [ ! -e "${target}" ]; then
        return 0
    fi
    if [ -n "${sudo_cmd}" ]; then
        "${sudo_cmd}" rm -rf "${target}" 2>/dev/null || true
    else
        rm -rf "${target}" 2>/dev/null || true
    fi
}

# User confirmation prompt (returns 0 on yes, 1 on no/skip)
confirm_action() {
    local desc="$1"
    if [ "${APPLY}" != true ]; then
        return 1
    fi
    if [ "${YES}" = true ]; then
        return 0
    fi
    local answer
    read -r -p "確認清理 ${desc}？ [y/N] " answer
    case "${answer}" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            echo "  - 已跳過 (Skipped)"
            return 1
            ;;
    esac
}

# Preview headers and footers
print_preview_header() {
    local component="$1"
    echo "=================================================================="
    echo " [Preview Mode] ${component} 清理目標預覽 (Dry-run)"
    echo "=================================================================="
    printf "%-52s %s\n" "TARGET" "ESTIMATED SIZE"
    printf "%-52s %s\n" "----------------------------------------------------" "--------------"
}

print_preview_target() {
    local target="$1"
    local size="$2"
    local note="${3:-}"
    if [ -n "${note}" ]; then
        printf "%-52s %s (%s)\n" "${target}" "${size}" "${note}"
    else
        printf "%-52s %s\n" "${target}" "${size}"
    fi
}

print_preview_footer() {
    echo "------------------------------------------------------------------"
    echo "預覽模式：未刪除任何檔案。若要執行清理，請加上 --apply 參數。"
    echo "例如: $0 --apply"
    echo "=================================================================="
}

# Apply headers
print_apply_header() {
    local component="$1"
    echo "=================================================================="
    echo " [Apply Mode] 執行 ${component} 清理"
    echo "=================================================================="
}
