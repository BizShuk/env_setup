#!/bin/bash
# Mac 啟動程序稽核腳本 (Launch Process Persistence Audit)
# 檢查所有 LaunchAgents / LaunchDaemons，找出可疑的持久化後門
# 執行方式：bash mac_launch_audit.sh

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

REPORT_DIR="$HOME/.config/system/data"
mkdir -p "$REPORT_DIR"
REPORT="${REPORT_DIR}/launch_audit-$(date +%Y%m%d).report.md"

term_log() {
  echo -e "$1"
}

md_log() {
  echo -e "$1" | sed $'s/\033[[0-9;]*m//g' >> "$REPORT"
}

log() {
  term_log "$1"
  md_log "$1"
}

header() {
  term_log "\n${BOLD}${CYAN}════════════════${NC}"
  term_log "${BOLD}${CYAN}  $1${NC}"
  term_log "${BOLD}${CYAN}════════════════${NC}"
  md_log "\n# $1"
}

run_cmd() {
  local cmd="$1"
  term_log "${CYAN}> $cmd${NC}"
  
  local cmd_out
  cmd_out=$(eval "$cmd" 2>&1)
  
  # 印在終端
  echo "$cmd_out"
  
  # 寫入 markdown
  echo "" >> "$REPORT"
  echo "\`\`\`text" >> "$REPORT"
  echo "$cmd_out" | sed $'s/\033[[0-9;]*m//g' >> "$REPORT"
  echo "\`\`\`" >> "$REPORT"
}

md_code_block_start() {
  md_log "\`\`\`text"
}

md_code_block_end() {
  md_log "\`\`\`"
}

# 已知正常的 Apple/系統 plist 前綴
WHITELIST=(
  "com.apple"
  "com.openssh"
  "org.cups"
  "com.microsoft"
  "com.google"
  "com.adobe"
  "com.dropbox"
  "com.spotify"
  "com.zoom"
  "org.mozilla"
  "com.1password"
  "io.tailscale"
  "com.docker"
  "com.homebrew"
  "com.anthropic"
  "com.jetbrains"
  "com.sublimetext"
  "com.github"
  "io.github"
)

is_whitelisted() {
  local name="$1"
  for prefix in "${WHITELIST[@]}"; do
    [[ "$name" == $prefix* ]] && return 0
  done
  return 1
}

# 確保 Markdown 報告第一行即為 H1 標題，避免 MD041 錯誤
echo "# 🔍 Mac 啟動程序稽核報告 (Launch Process Persistence Audit)" > "$REPORT"
term_log "🔍 Mac 啟動程序稽核報告 (Launch Process Persistence Audit)"

log "分析時間：\`$(date)\`"
log "使用者：\`$(whoami)\`"
log ""
log "說明：LaunchAgents / LaunchDaemons 是 macOS 的「開機自動執行清單」。"
log "駭客常用這裡埋後門，讓惡意程式在開機後自動啟動。"
log "核心概念：開機自動啟動的程式如果沒有被使用者審核，就可能藏有安全隱患。"
log ""

# ---- 掃描函式 ----
scan_dir() {
  local dir="$1"
  local label="$2"

  term_log "\n════════════════"
  term_log "📁 $label"
  term_log "路徑：$dir"
  term_log "════════════════"
  
  md_log "\n## $label"
  md_log "路徑：\`$dir\`\n"

  if [ ! -d "$dir" ]; then
    log "（目錄不存在，跳過）"
    return
  fi

  local count=0
  local suspicious=0

  for plist in "$dir"/*.plist; do
    [ -f "$plist" ] || continue
    count=$((count + 1))

    filename=$(basename "$plist" .plist)
    mod_date=$(GetFileInfo -m "$plist" 2>/dev/null || stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$plist" 2>/dev/null)
    size=$(du -h "$plist" 2>/dev/null | cut -f1)

    # 取出 plist 裡的關鍵欄位
    program=$(defaults read "$plist" ProgramArguments 2>/dev/null | tr -d '\n ()' | head -c 100)
    run_at_load=$(defaults read "$plist" RunAtLoad 2>/dev/null)
    keep_alive=$(defaults read "$plist" KeepAlive 2>/dev/null)
    disabled=$(defaults read "$plist" Disabled 2>/dev/null)

    # 判斷是否可疑
    flags=""
    is_whitelisted "$filename" || flags="$flags [\`⚠️ 非標準來源\`]"
    [[ "$program" == *"/tmp/"* ]] && flags="$flags [\`🔴 執行 /tmp 路徑\`]"
    [[ "$program" == *"/var/folders/"* ]] && flags="$flags [\`🔴 執行暫存路徑\`]"
    [[ "$program" == *"curl"* || "$program" == *"wget"* ]] && flags="$flags [\`🔴 含下載指令\`]"
    [[ "$program" == *"base64"* || "$program" == *"eval"* ]] && flags="$flags [\`🔴 含混淆指令\`]"
    [[ "$program" == *"python"* || "$program" == *"ruby"* || "$program" == *"perl"* ]] && flags="$flags [\`⚠️ 腳本語言\`]"
    [[ "$keep_alive" == "1" || "$keep_alive" == *"true"* ]] && flags="$flags [\`⚠️ KeepAlive=開啟\`]"

    if [ -n "$flags" ]; then
      suspicious=$((suspicious + 1))
      # 終端輸出
      term_log "\n  🚨 ${RED}$filename${NC}"
      term_log "     修改日期：$mod_date | 大小：$size"
      term_log "     程式：$program"
      term_log "     RunAtLoad=$run_at_load | KeepAlive=$keep_alive | Disabled=$disabled"
      term_log "     標記：$flags"
      
      # Markdown 輸出
      md_log "\n- 🚨 \`$filename\`"
      md_log "  - 修改日期：\`$mod_date\` | 大小：\`$size\`"
      md_log "  - 程式：\`$program\`"
      md_log "  - \`RunAtLoad=$run_at_load\` | \`KeepAlive=$keep_alive\` | \`Disabled=$disabled\`"
      md_log "  - 標記：$flags"
    else
      term_log "  ✅ ${GREEN}$filename${NC}  [$mod_date]"
      md_log "- ✅ \`$filename\`  [\`$mod_date\`]"
    fi
  done

  log "\n  共 \`$count\` 個項目，\`$suspicious\` 個標記為可疑"
}

# ---- 掃描六個位置 ----
scan_dir "$HOME/Library/LaunchAgents"           "使用者 LaunchAgents（最常被濫用）"
scan_dir "/Library/LaunchAgents"                "系統 LaunchAgents（所有使用者）"
scan_dir "/Library/LaunchDaemons"               "系統 LaunchDaemons（最高權限，root 執行）"
scan_dir "/System/Library/LaunchAgents"         "Apple 官方 LaunchAgents"
scan_dir "/System/Library/LaunchDaemons"        "Apple 官方 LaunchDaemons"

# ---- 目前已載入的 Launch Services ----
header "已載入的非 Apple Launch Services（launchctl list）"
log "只顯示非 com.apple.* 的項目：\n"
run_cmd 'launchctl list 2>/dev/null | grep -v "^-\|com\.apple\|PID\|Label" | awk '\''{print $3, "(PID="$1", 上次退出碼="$2")"}'\'' | grep -v "^$" | sort'

# ---- 近 30 天新增/修改 the plist ----
header "近 30 天新增或修改的 Launch plist（可疑時間點）"
md_code_block_start
plist_out=$(for dir in \
  "$HOME/Library/LaunchAgents" \
  "/Library/LaunchAgents" \
  "/Library/LaunchDaemons"; do
  find "$dir" -name "*.plist" -newer "$(date -v-30d +%Y%m%d 2>/dev/null || date -d '30 days ago' +%Y%m%d 2>/dev/null || echo '20260501')" 2>/dev/null \
    | while read f; do
        echo "  $(stat -f "%Sm  %N" -t "%Y-%m-%d" "$f" 2>/dev/null)"
      done
done)
echo "$plist_out"
echo "$plist_out" >> "$REPORT"
md_code_block_end

# ---- 摘要 ----
log ""
log "✅ 稽核完成。完整報告已儲存至：\`$REPORT\`"
log ""
log "建議：把此報告複製給 Claude，針對「\`⚠️ 非標準來源\`」和「\`🔴\`」項目進行逐一核查。"
echo ""
echo "報告路徑：$REPORT"

