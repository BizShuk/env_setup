#!/bin/bash
# macOS Network Security Audit Script
# Run: bash network_security_audit-mac.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=_lib_audit.sh
. "$SCRIPT_DIR/_lib_audit.sh"

audit_init "network_security_audit"

# 覆寫 header 為 H1 標題
header() {
  term_log "\n${BOLD}${CYAN}════════════════${NC}"
  term_log "${BOLD}${CYAN}  $1${NC}"
  term_log "${BOLD}${CYAN}════════════════\n${NC}"
  md_log "\n# $1"
}

subheader() {
  term_log "\n${BOLD}${YELLOW}▶ $1${NC}"
  md_log "\n## $1"
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
echo "# 🛡️  macOS 網路安全稽核報告 (Network Security Audit)" > "$REPORT_FILE"
term_log "🛡️  macOS 網路安全稽核報告 (Network Security Audit)"

log "分析時間：\`$(date)\`"
log "主機名稱 (Hostname)：\`$(hostname)\`"
log "目前使用者 (Current User)：\`$(whoami)\`"

# ------------------------------------------------------------------------------
# 1. OPEN PORTS & LISTENING SERVICES
# ------------------------------------------------------------------------------
header "1. 開放連接埠與監聽服務 (Open Ports & Listening Services)"

log "TCP 監聽連接埠 (TCP Listening Ports):"
run_cmd "sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null"

log "\nUDP 連接埠 (UDP Ports):"
run_cmd "sudo lsof -nP -iUDP 2>/dev/null | grep -v '^COMMAND'"

# ------------------------------------------------------------------------------
# 2. FIREWALL STATUS
# ------------------------------------------------------------------------------
header "2. 防火牆狀態 (Firewall Status)"

subheader "應用程式防火牆 (Application Firewall)"
run_cmd "/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null"
run_cmd "/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>/dev/null"
run_cmd "/usr/libexec/ApplicationFirewall/socketfilterfw --getblockall 2>/dev/null"
run_cmd "/usr/libexec/ApplicationFirewall/socketfilterfw --listapps 2>/dev/null"

subheader "封包過濾防火牆 (Packet Filter - pf)"
run_cmd "sudo pfctl -s info 2>/dev/null | head -20"

subheader "目前作用中的 pf 規則 (Active pf Rules)"
run_cmd "sudo pfctl -s rules 2>/dev/null | head -30"

# ------------------------------------------------------------------------------
# 3. ACTIVE NETWORK CONNECTIONS
# ------------------------------------------------------------------------------
header "3. 作用中的網路連線 (Active Network Connections)"

subheader "已建立的 TCP 連線 (Established TCP Connections)"
run_cmd "sudo lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null"

subheader "所有外部連線 - 排除本機 (All Foreign Connections - Non-Local)"
run_cmd "sudo lsof -nP -i 2>/dev/null | grep -v '127\.0\.0\|::1\|LISTEN\|^COMMAND' | head -60"

# ------------------------------------------------------------------------------
# 4. DNS CONFIGURATION
# ------------------------------------------------------------------------------
header "4. 網域名稱系統解析設定 (DNS Configuration)"

subheader "\`/etc/resolv.conf\` 檔案內容"
if [ -f /etc/resolv.conf ]; then
  run_cmd "cat /etc/resolv.conf"
else
  log "（檔案不存在，跳過）"
fi

subheader "系統組態 DNS (scutil DNS)"
run_cmd "scutil --dns 2>/dev/null | head -40"

subheader "網路介面 DNS 設定 (networksetup)"
run_cmd "networksetup -listallnetworkservices 2>/dev/null | tail -n +2 | while read -r svc; do dns=\$(networksetup -getdnsservers \"\$svc\" 2>/dev/null); printf '%s: %s\n' \"\$svc\" \"\$dns\"; done"

subheader "\`/etc/hosts\` (排除註解項目)"
run_cmd "grep -v '^#\|^$' /etc/hosts 2>/dev/null"

# ------------------------------------------------------------------------------
# 5. SHARING SERVICES STATUS
# ------------------------------------------------------------------------------
header "5. 系統共享服務狀態 (Sharing Services Status)"

subheader "安全命令列遠端登入 (SSH / Remote Login)"
run_cmd "sudo systemsetup -getremotelogin 2>/dev/null"
run_cmd "sudo launchctl list com.openssh.sshd 2>/dev/null && printf 'SSH daemon: RUNNING\n' || printf 'SSH daemon: not running\n'"

subheader "檔案共享服務 (File Sharing - AFP/SMB)"
run_cmd "sudo launchctl list com.apple.smbd 2>/dev/null && printf 'SMB: RUNNING\n' || printf 'SMB: not running\n'"
run_cmd "sudo launchctl list com.apple.AppleFileServer 2>/dev/null && printf 'AFP: RUNNING\n' || printf 'AFP: not running\n'"

subheader "螢幕共享與遠端桌面 (Screen Sharing / VNC)"
run_cmd "sudo launchctl list com.apple.screensharing 2>/dev/null && printf 'Screen Sharing: RUNNING\n' || printf 'Screen Sharing: not running\n'"

subheader "所有共享相關的 launchctl 服務"
run_cmd "sudo launchctl list 2>/dev/null | grep -iE 'ssh|smb|afp|vnc|share|ftp|remote|http'"

subheader "Bonjour 服務 (Bonjour / mDNSResponder)"
run_cmd "sudo launchctl list com.apple.mDNSResponder 2>/dev/null && printf 'mDNSResponder: RUNNING\n' || printf 'mDNSResponder: not running\n'"

# ------------------------------------------------------------------------------
# 6. WI-FI SECURITY
# ------------------------------------------------------------------------------
header "6. Wi-Fi 無線網路安全 (Wi-Fi Security)"

subheader "目前 Wi-Fi 連線狀態 (Current Wi-Fi Connection)"
run_cmd "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null"

subheader "網路介面卡配置 (Network Interfaces)"
run_cmd "ifconfig 2>/dev/null | grep -A6 '^en'"

subheader "系統描述程式之 Wi-Fi 狀態 (System Profiler Wi-Fi)"
run_cmd "system_profiler SPAirPortDataType 2>/dev/null | grep -E 'Current Network|SSID|Security|Channel|Country|PHY Mode|Network Service ID' | head -30"

# ------------------------------------------------------------------------------
# 7. PROCESSES WITH NETWORK CONNECTIONS
# ------------------------------------------------------------------------------
header "7. 具備網路連線之處理程序 (Processes with Network Connections)"

subheader "所有建立網路通訊端之處理程序 (Open Network Sockets)"
run_cmd "sudo lsof -nP -i 2>/dev/null | awk 'NR==1 || /ESTABLISHED|LISTEN/' | sort -k1 | head -80"

subheader "處理程序的聯外連線 (Outbound Connections by Process)"
run_cmd "sudo lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null | awk '{print \$1, \$9}' | sort -u"

subheader "異常監聽連接埠 - 非標準 (Unusual Listening Ports)"
run_cmd "sudo lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR>1 {split(\$9,a,\":\"); print \$1, \$2, a[length(a)]}' | sort -k3 -n"

# ------------------------------------------------------------------------------
# 8. NETWORK INTERFACES SUMMARY
# ------------------------------------------------------------------------------
header "8. 網路介面與路由表摘要 (Network Interfaces Summary)"

log "網路介面卡摘要資訊 (Network Interfaces IP & Status):"
run_cmd "ifconfig -a 2>/dev/null | grep -E '^[a-z]|inet |status:'"

subheader "系統路由表 (Routing Table)"
run_cmd "netstat -rn 2>/dev/null | head -30"

# ------------------------------------------------------------------------------
# AUDIT COMPLETE
# ------------------------------------------------------------------------------
log "\n═══════════════════════════════════════════════════════"
log "✅ 稽核完成時間：\`$(date)\`"
log "報告儲存於：\`$REPORT_FILE\`"
echo ""
echo -e "${GREEN}✅ 完成！報告已儲存：$REPORT_FILE${NC}"

