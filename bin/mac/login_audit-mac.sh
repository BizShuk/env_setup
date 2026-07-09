#!/bin/bash
# Mac 登入歷史稽核腳本 (Mac Login History Audit Script)
# 執行方式：bash mac_login_audit.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib_audit.sh
. "$SCRIPT_DIR/_lib_audit.sh"

audit_init "login_audit"

# 覆寫 header 為 H1 標題
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
  echo "" >> "$REPORT_FILE"
  echo "\`\`\`text" >> "$REPORT_FILE"
  echo "$cmd_out" | sed $'s/\033[[0-9;]*m//g' >> "$REPORT_FILE"
  echo "\`\`\`" >> "$REPORT_FILE"
}

# 確保 Markdown 報告第一行即為 H1 標題，避免 MD041 錯誤
echo "# 🔐 Mac 登入歷史稽核報告 (Login History Audit)" > "$REPORT_FILE"
term_log "🔐 Mac 登入歷史稽核報告 (Login History Audit)"

log "分析時間：\`$(date)\`"
log "主機名稱 (Hostname)：\`$(hostname)\`"
log "目前使用者 (Current User)：\`$(whoami)\`"

# 1. 目前登入中的使用者
header "1. 目前登入中的使用者 (Currently Logged In Users)"
run_cmd "who"
log "登入數量：\`$(who | wc -l | tr -d ' ')\` 個工作階段 (sessions)"

# 2. 完整登入歷史 (last)
header "2. 完整登入歷史 - 最近 50 筆 (Login History - Last 50 entries)"
log "格式說明：使用者名稱 | 終端機 | 來源 IP 或本機 | 登入時間 | 登出時間 | 持續時間\n"
run_cmd "last | head -50"

# 3. 只列出遠端登入 (SSH)
header "3. 遠端 SSH 登入紀錄 (Remote SSH Logins)"
SSH_LOGINS=$(last | grep -v "^wtmp\|^reboot\|^shutdown\|console\|ttyv" | grep "\." | head -20)
if [ -z "$SSH_LOGINS" ]; then
  log "✅ 無遠端 SSH 登入紀錄"
else
  log "⚠️  發現遠端登入："
  run_cmd 'last | grep -v "^wtmp\|^reboot\|^shutdown\|console\|ttyv" | grep "\." | head -20'
fi

# 4. 系統重開機/關機紀錄
header "4. 系統重開機/關機紀錄 (Reboot / Shutdown History)"
log "重開機紀錄 (Reboot History)："
run_cmd "last reboot | head -10"
log "\n關機紀錄 (Shutdown History)："
run_cmd "last shutdown | head -10"

# 5. 失敗的登入嘗試 (近 7 天)
header "5. 失敗的登入嘗試 - 近 7 天 (Failed Login Attempts - Last 7 Days)"
log "正在查詢系統日誌，可能需要幾秒..."
FAILED=$(log show --predicate 'eventMessage contains "Failed password" OR eventMessage contains "Invalid user" OR eventMessage contains "authentication error"' --last 7d 2>/dev/null | grep -v "^Filtering" | head -30)
if [ -z "$FAILED" ]; then
  log "✅ 近 7 天無失敗登入嘗試"
else
  log "⚠️  發現失敗登入嘗試："
  run_cmd "log show --predicate 'eventMessage contains \"Failed password\" OR eventMessage contains \"Invalid user\" OR eventMessage contains \"authentication error\"' --last 7d 2>/dev/null | grep -v '^Filtering' | head -30"
fi

# 6. sudo 使用紀錄 (近 24 小時)
header "6. sudo 權限提升紀錄 - 近 24 小時 (sudo Usage - Last 24 Hours)"
SUDO_LOG=$(log show --predicate 'eventMessage contains "sudo"' --last 24h 2>/dev/null | grep -v "^Filtering" | head -20)
if [ -z "$SUDO_LOG" ]; then
  log "近 24 小時無 sudo 使用紀錄"
else
  run_cmd "log show --predicate 'eventMessage contains \"sudo\"' --last 24h 2>/dev/null | grep -v '^Filtering' | head -20"
fi

# 7. 螢幕解鎖/鎖定紀錄 (近 24 小時)
header "7. 螢幕解鎖/鎖定紀錄 - 近 24 小時 (Screen Lock/Unlock - Last 24 Hours)"
run_cmd "log show --predicate 'eventMessage contains \"screensaver\" OR eventMessage contains \"unlocked\" OR eventMessage contains \"locked\"' --last 24h 2>/dev/null | grep -v '^Filtering' | tail -20"

# 8. 異常偵測
header "8. 🔍 異常偵測摘要 (Anomaly Detection Summary)"

# 統計不同 IP 的 SSH 嘗試
UNIQUE_IPS=$(last | grep "\." | awk '{print $3}' | sort -u | grep -v "^$")
if [ -n "$UNIQUE_IPS" ]; then
  log "⚠️  曾有遠端連線來自以下 IP："
  run_cmd "last | grep '\.' | awk '{print \$3}' | sort -u | grep -v '^$'"
else
  log "✅ 無遠端 IP 登入紀錄"
fi

# 非正常時間登入 (午夜 00:00 - 06:00)
log "\n深夜登入檢查（凌晨 0-6 點）："
LATE_LOGINS=$(last | grep -E " [0-2][0-9]:[0-9][0-9]" | awk '{
  split($7, t, ":")
  if (t[1]+0 >= 0 && t[1]+0 <= 5) print $0
}' | head -10)
if [ -n "$LATE_LOGINS" ]; then
  log "⚠️  發現深夜登入（凌晨 0-6 點）："
  run_cmd "last | grep -E ' [0-2][0-9]:[0-9][0-9]' | awk '{ split(\$7, t, \":\"); if (t[1]+0 >= 0 && t[1]+0 <= 5) print \$0 }' | head -10"
else
  log "✅ 無深夜異常登入"
fi

# 9. 目前所有使用者帳號
header "9. 系統所有本機使用者帳號 (All Local User Accounts)"
run_cmd 'dscl . list /Users | grep -v "^_\|daemon\|nobody\|root"'

log ""
log "✅ 稽核完成。報告已儲存至：\`$REPORT_FILE\`"
echo ""
echo "報告路徑：$REPORT_FILE"
echo "如有可疑項目，請把報告內容複製給 Claude 進行進一步分析。"

