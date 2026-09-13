#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Validate operating system
if [ "$(uname -s)" != "Darwin" ]; then
    echo "Error: macOS defaults backup requires Darwin (macOS). Current OS: $(uname -s)" >&2
    exit 1
fi

FORCE=false
for arg in "$@"; do
    case "${arg}" in
        --force|-f)
            FORCE=true
            ;;
        --help|-h)
            echo "Usage: $(basename "$0") [--force|-f]"
            echo "Initialize ~/.config/env_setup/mac_backup_domains.json with default tracked domains."
            exit 0
            ;;
        *)
            echo "Error: unknown argument '${arg}'" >&2
            echo "Usage: $(basename "$0") [--force|-f]" >&2
            exit 1
            ;;
    esac
done

CONFIG_DIR="${CONFIG_DIR:-${HOME}/.config/env_setup}"
MANIFEST_FILE="${MANIFEST_FILE:-${CONFIG_DIR}/mac_backup_domains.json}"
DEFAULT_TEMPLATE="${REPO_DIR}/svc/backup/mac_backup_domains.default.json"

mkdir -p "${CONFIG_DIR}"

if [ -f "${MANIFEST_FILE}" ] && [ "${FORCE}" = false ]; then
    echo "網域清單已存在: ${MANIFEST_FILE} (略過建立，使用 --force 覆寫)"
    exit 0
fi

if [ -f "${DEFAULT_TEMPLATE}" ]; then
    cp "${DEFAULT_TEMPLATE}" "${MANIFEST_FILE}"
else
    cat << 'EOF' > "${MANIFEST_FILE}"
[
  { "domain": "com.apple.dock",                                    "note": "Dock 位置、大小、magnification、自動隱藏" },
  { "domain": "com.apple.finder",                                  "note": "Finder 檢視、副檔名、路徑列、搜尋範圍" },
  { "domain": "com.apple.symbolichotkeys",                         "note": "系統快捷鍵 (Spotlight / 截圖 / Mission Control)" },
  { "domain": "com.apple.screencapture",                           "note": "截圖格式、儲存位置、陰影" },
  { "domain": "com.apple.menuextra.clock",                         "note": "選單列時鐘格式" },
  { "domain": "com.apple.controlcenter",                           "note": "控制中心 / 選單列項目顯示" },
  { "domain": "com.apple.AppleMultitouchTrackpad",                 "note": "內建觸控板手勢與敲擊" },
  { "domain": "com.apple.driver.AppleBluetoothMultitouch.trackpad","note": "藍牙觸控板手勢與敲擊" },
  { "domain": "NSGlobalDomain",                                    "note": "全域偏好 (鍵盤重複、捲動、tap-to-click、App 快捷鍵)" }
]
EOF
fi

echo "網域清單已就緒: ${MANIFEST_FILE}"
