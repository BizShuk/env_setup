#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi

OS="${OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

usage() {
    echo "Usage: $(basename "$0") [--yes|-y] <volume-path>"
    echo ""
    echo "使用 F3 (Fight Flash Fraud) 驗證隨身碟/磁碟之實際容量與資料完整性。"
    echo ""
    echo "Options:"
    echo "  --yes, -y    略過確認提示並立即執行 F3 verification"
    echo "  --help, -h   顯示此說明訊息"
    echo ""
    echo "Example:"
    echo "  $(basename "$0") /Volumes/USB_DRIVE"
    echo "  $(basename "$0") --yes /Volumes/USB_DRIVE"
}

yes_mode=0
volume_path=""

while [ $# -gt 0 ]; do
    case "$1" in
        --yes|-y)
            yes_mode=1
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        -*)
            echo "Error: unknown argument '$1'" >&2
            usage >&2
            exit 1
            ;;
        *)
            if [ -z "$volume_path" ]; then
                volume_path="$1"
            else
                echo "Error: unexpected multiple volume paths provided ('${volume_path}' and '$1')" >&2
                usage >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "$volume_path" ]; then
    echo "Error: volume path is required" >&2
    usage >&2
    exit 1
fi

if [ ! -d "$volume_path" ]; then
    echo "Error: volume path '${volume_path}' does not exist or is not a directory" >&2
    exit 1
fi

# Check for f3write and f3read availability
missing_cmds=()
if ! command -v f3write >/dev/null 2>&1; then missing_cmds+=("f3write"); fi
if ! command -v f3read >/dev/null 2>&1; then missing_cmds+=("f3read"); fi

if [ ${#missing_cmds[@]} -gt 0 ]; then
    echo "Error: required command(s) missing: ${missing_cmds[*]}" >&2
    if [ "$OS" = "darwin" ]; then
        echo "Please install F3 via Homebrew: brew install f3" >&2
    else
        echo "Please install F3 via package manager: sudo apt-get install f3 (Debian/Ubuntu) or brew install f3" >&2
    fi
    exit 1
fi

if [ "$OS" = "darwin" ] && ! command -v diskutil >/dev/null 2>&1; then
    echo "Error: 'diskutil' command not found." >&2
    exit 1
fi

if [ "$yes_mode" -eq 0 ]; then
    printf "F3 將寫入 test files 直到 %s 的可用空間用盡，再讀回驗證；繼續？ [y/N] " "${volume_path}"
    read -r answer || answer=""
    case "$(echo "$answer" | tr '[:upper:]' '[:lower:]' | xargs)" in
        y|yes) ;;
        *)
            echo "略過 F3 disk verification。"
            exit 0
            ;;
    esac
fi

echo "=================================================="
echo "F3 磁碟容量與完整性驗證 (Disk Verification)"
echo "目標路徑 (Target Path): ${volume_path}"
echo "=================================================="

if [ "$OS" = "darwin" ]; then
    echo "==> 步驟 1/3: 檢視磁碟資訊 (diskutil info)..."
    if ! diskutil info "${volume_path}" 2>/dev/null; then
        mount_point=$(df -P "${volume_path}" 2>/dev/null | tail -n 1 | awk '{print $NF}' || echo "")
        if [ -n "$mount_point" ] && [ "$mount_point" != "${volume_path}" ]; then
            diskutil info "${mount_point}"
        else
            df -h "${volume_path}"
        fi
    fi
else
    echo "==> 步驟 1/3: 檢視掛載點資訊 (df -h)..."
    df -h "${volume_path}"
fi

echo ""
echo "==> 步驟 2/3: 寫入測試檔案 (f3write)..."
f3write "${volume_path}"

echo ""
echo "==> 步驟 3/3: 讀取並驗證檔案 (f3read)..."
f3read "${volume_path}"

echo ""
echo "驗證完成 (Disk verification finished successfully)。"
