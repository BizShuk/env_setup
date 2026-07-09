#!/bin/bash
# _lib_audit.sh — macOS 稽核腳本共用 helper
#
# 提供功能:
#   1. 顏色常數 (RED / YELLOW / GREEN / CYAN / BOLD / NC)
#   2. 報告路徑常數 (REPORT_DIR) 與日期標記 (REPORT_FILE)
#   3. 輸出函式:
#        term_log  - 印到終端 (保留顏色)
#        md_log    - 寫入 Markdown 報告 (去除 ANSI 碼)
#        log       - 同時輸出終端 + Markdown
#        header    - 印出分隔線 + 區塊標題
#        status    - 狀態圖示 (✓/✗/⚠)
#
# 用法 (Usage):
#   source "$(dirname "$0")/_lib_audit.sh"
#   audit_init "disk_analysis"            # 設定 REPORT_FILE
#   header "Disk Analysis Report"
#   log "Hello World"

# ----------------------------------------------------------------------------
# 顏色常數 (Color Constants)
# ----------------------------------------------------------------------------
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ----------------------------------------------------------------------------
# 報告路徑 (Report Paths)
# ----------------------------------------------------------------------------
REPORT_DIR="${AUDIT_REPORT_DIR:-$HOME/.config/system/data}"
mkdir -p "$REPORT_DIR"

# ----------------------------------------------------------------------------
# audit_init: 設定報告檔名
#   $1 = 報告前綴 (例: "disk_analysis"), 預設 "audit"
#   $2 = 副檔名前綴, 預設與 $1 同
#   範例: audit_init "disk_analysis"  ->  ${REPORT_DIR}/disk_analysis-YYYYMMDD.report.md
# ----------------------------------------------------------------------------
audit_init() {
    local prefix="${1:-audit}"
    local report_file="${REPORT_DIR}/${prefix}-$(date +%Y%m%d).report.md"
    # 將變數綁到 caller 的 scope
    # shellcheck disable=SC2034
    REPORT_FILE="$report_file"
    : > "$REPORT_FILE"   # truncate 既有報告
}

# ----------------------------------------------------------------------------
# 輸出函式 (Output Functions)
# ----------------------------------------------------------------------------
term_log() {
    echo -e "$1"
}

md_log() {
    echo -e "$1" | sed $'s/\033[[0-9;]*m//g' >> "$REPORT_FILE"
}

log() {
    term_log "$1"
    md_log "$1"
}

# header: 印出分隔線 + 標題
#   $1 = 標題文字
header() {
    term_log "\n${BOLD}${CYAN}══════════════════════════════════════${NC}"
    term_log "${BOLD}${CYAN}  $1${NC}"
    term_log "${BOLD}${CYAN}══════════════════════════════════════${NC}\n"
    md_log ""
    md_log "## $1"
    md_log ""
}

# status: 輸出狀態圖示 + 訊息
#   $1 = 狀態 (ok/warn/fail)
#   $2 = 訊息
status() {
    case "$1" in
        ok)   log "${GREEN}✓${NC} $2" ;;
        warn) log "${YELLOW}⚠${NC} $2" ;;
        fail) log "${RED}✗${NC} $2" ;;
        *)    log "  $2" ;;
    esac
}

# ----------------------------------------------------------------------------
# 環境守衛 (Pre-flight): 僅允許 macOS
# ----------------------------------------------------------------------------
audit_require_macos() {
    if [ "$(uname -s)" != "Darwin" ]; then
        echo "ERROR: This audit script requires macOS. Current: $(uname -s)" >&2
        exit 1
    fi
}
