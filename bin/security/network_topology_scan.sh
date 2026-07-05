#!/bin/bash
# ============================================================
#  macOS 網路拓撲安全掃描腳本 (Network Topology Security Scan)
#  從本機私有網段逐層 traceroute 直到公網入口，沿途 nmap 服務偵測 + 規則式風險評估
#
#  使用方式 (Usage):
#    bash network_topology_scan-mac.sh                 # 完整模式 (traceroute + nmap -sV + 風險評估)
#    bash network_topology_scan-mac.sh --no-scan       # 只做路徑追蹤，不對網段發 nmap 封包
#    bash network_topology_scan-mac.sh --target 1.1.1.1  # 自訂 traceroute 出口目標
# ============================================================

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ─── CLI 解析 (Argument Parsing) ──────────────────────────
DO_SCAN=true
TARGET="8.8.8.8"

usage() {
  cat <<'EOF'
網路拓撲安全掃描 (Network Topology Security Scan)

用法 (Usage):
  network_topology_scan-mac.sh [--no-scan] [--target <host>] [-h|--help]

旗標 (Flags):
  --no-scan          只做 traceroute 路徑追蹤，不對任何網段發送 nmap 封包
  --target <host>    traceroute 出口目標 (預設: 8.8.8.8)
  -h, --help         顯示此說明

完整模式相依: traceroute, nmap
--no-scan 模式相依: traceroute
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --no-scan) DO_SCAN=false; shift ;;
    --target)  TARGET="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知參數 (Unknown argument): $1" >&2; usage; exit 1 ;;
  esac
done

# ─── 相依檢查 (Dependency Check) ──────────────────────────
if ! command -v traceroute &>/dev/null; then
  echo "錯誤 (Error): 缺少必要相依 'traceroute'，請先安裝。" >&2
  exit 1
fi
if [ "$DO_SCAN" = true ] && ! command -v nmap &>/dev/null; then
  echo "錯誤 (Error): 完整模式需要 'nmap'，請先安裝，或改用 --no-scan 模式。" >&2
  exit 1
fi

# ─── Sudo 檢查與重啟 (Sudo Check & Re-run) ─────────────────
if [ "$DO_SCAN" = true ] && [ "$(id -u)" -ne 0 ]; then
  if [ -t 0 ]; then
    echo -n "是否要以 sudo 重新執行本腳本以取得完整結果 (含 OS 偵測與 SYN 掃描)？[y/N] (1 分鐘內未輸入則預設不使用): "
    if read -t 60 -r response; then
      if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "正在以 sudo 重新執行腳本..."
        exec sudo bash "$0" "$@"
      else
        echo "繼續以目前權限執行（略過 OS 偵測）..."
      fi
    else
      echo -e "\n[超時] 未在一分鐘內輸入，預設不使用 sudo，繼續執行..."
    fi
  else
    echo "提示：非互動式終端，繼續以目前權限執行（略過 OS 偵測）..."
  fi
fi

# ─── 報告檔案設定 (Report File Setup) ─────────────────────
REPORT_DIR="$HOME/.config/system/data"
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/network_topology_scan-$(date +%Y%m%d).report.md"

# ─── 輸出 Helper (與 network_security_audit-mac.sh 同構) ──
term_log() { echo -e "$1"; }
md_log()   { echo -e "$1" | sed $'s/\033[[0-9;]*m//g' >> "$REPORT_FILE"; }
log()      { term_log "$1"; md_log "$1"; }

header() {
  term_log "\n${BOLD}${CYAN}════════════════${NC}"
  term_log "${BOLD}${CYAN}  $1${NC}"
  term_log "${BOLD}${CYAN}════════════════\n${NC}"
  md_log "\n## $1\n"
}

subheader() {
  term_log "\n${BOLD}${YELLOW}▶ $1${NC}"
  md_log "\n### $1\n"
}

# 執行指令並包裝於 Markdown code block 內
run_cmd() {
  local cmd="$1"
  term_log "${CYAN}> $cmd${NC}"
  local cmd_out
  cmd_out=$(eval "$cmd" 2>&1)
  echo "$cmd_out"
  echo "" >> "$REPORT_FILE"
  echo "\`\`\`text" >> "$REPORT_FILE"
  echo "$cmd_out" | sed $'s/\033[[0-9;]*m//g' >> "$REPORT_FILE"
  echo "\`\`\`" >> "$REPORT_FILE"
}

# 寫入一段純文字 code block (給已算好的輸出，避免重跑指令)
emit_block() {
  local content="$1"
  echo "$content"
  echo "" >> "$REPORT_FILE"
  echo "\`\`\`text" >> "$REPORT_FILE"
  echo "$content" | sed $'s/\033[[0-9;]*m//g' >> "$REPORT_FILE"
  echo "\`\`\`" >> "$REPORT_FILE"
}

# ─── 工具函式 (Helpers) ───────────────────────────────────

# 判斷是否為私有 IP (RFC1918 + CGNAT 100.64/10)
is_private() {
  local ip=$1
  if [[ $ip =~ ^10\. ]] ||
     [[ $ip =~ ^192\.168\. ]] ||
     [[ $ip =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] ||
     [[ $ip =~ ^100\.(6[4-9]|[7-9][0-9]|1[0-1][0-9]|12[0-7])\. ]]; then
    return 0
  fi
  return 1
}

get_local_ip() {
  ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | head -n1 | awk '{print $2}'
}

# 風險分類: 危險埠查表 → "嚴重度|類別|描述|修復"
# 嚴重度: CRIT / HIGH / MED / LOW
classify_port() {
  local port="$1" svc="$2"
  case "$port" in
    23)    echo "CRIT|1|Telnet (23) 明文遠端登入直接暴露於網路|停用 Telnet，改用 SSH" ;;
    21)    echo "HIGH|1|FTP (21) 明文檔案傳輸暴露|改用 SFTP/FTPS，或關閉服務" ;;
    3389)  echo "HIGH|1|RDP (3389) 遠端桌面暴露，常見暴力破解目標|限制來源 IP 或改用 VPN" ;;
    5900)  echo "HIGH|1|VNC (5900) 遠端桌面暴露|加上強密碼並限制來源，或改走 SSH 通道" ;;
    6379)  echo "HIGH|8|Redis (6379) 預設無認證，暴露可被任意讀寫|啟用 requirepass 並綁定內網介面" ;;
    27017) echo "HIGH|8|MongoDB (27017) 暴露，預設可能無認證|啟用認證並限制 bindIp" ;;
    445)   echo "MED|1|SMB (445) 檔案共享暴露|限制來源 IP，停用 SMBv1" ;;
    139)   echo "MED|1|NetBIOS/SMB (139) 暴露|關閉不必要的檔案共享" ;;
    135)   echo "MED|1|MSRPC (135) 暴露|防火牆阻擋對外存取" ;;
    161)   echo "MED|6|SNMP (161) 暴露，可能洩漏裝置資訊|改用 SNMPv3 並更換預設 community" ;;
    1433)  echo "MED|8|MSSQL (1433) 資料庫埠暴露|限制來源 IP，勿對外開放" ;;
    3306)  echo "MED|8|MySQL (3306) 資料庫埠暴露|綁定內網介面，限制來源 IP" ;;
    5432)  echo "MED|8|PostgreSQL (5432) 資料庫埠暴露|設定 pg_hba.conf 限制來源" ;;
    9200)  echo "MED|8|Elasticsearch (9200) 暴露，預設無認證|啟用安全功能並限制來源" ;;
    *)     echo "" ;;
  esac
}

# 版本 CVE 比對: 傳入服務版本字串，回傳 "嚴重度|類別|描述|證據|修復" 或空
classify_version() {
  local version="$1"
  if echo "$version" | grep -qE "OpenSSH 9\.6p1"; then
    echo "CRIT|2|OpenSSH 9.6p1 存在 CVE-2024-6387 (regreSSHion)，可能導致未授權遠端程式碼執行|$version|更新 OpenSSH 至 9.8p1 或更高版本"
  fi
}

# ─── 報告開頭 (Header Metadata) ───────────────────────────
MODE_LABEL="完整模式 (Full: traceroute + nmap -sV + 風險評估)"
[ "$DO_SCAN" = false ] && MODE_LABEL="路徑追蹤模式 (--no-scan: 只做 traceroute)"

echo -e "# 🛰️  網路拓撲安全掃描報告 (Network Topology Security Scan)\n" > "$REPORT_FILE"
term_log "🛰️  網路拓撲安全掃描報告 (Network Topology Security Scan)"

LOCAL_IP=$(get_local_ip)
LOCAL_HOSTNAME=$(hostname | sed 's/\.local$//')

TARGET_IP=$(traceroute -n -m 1 -q 1 "$TARGET" 2>&1 | grep -oE "\(([0-9]{1,3}\.){3}[0-9]{1,3}\)" | head -n1 | tr -d '()')
if [ -n "$TARGET_IP" ] && [ "$TARGET_IP" != "$TARGET" ]; then
  TARGET_DISPLAY="${TARGET} (${TARGET_IP})"
else
  TARGET_DISPLAY="${TARGET}"
fi

log "掃描日期 (Scan Date)：\`$(date '+%Y-%m-%d %H:%M:%S')\`"
log "掃描模式 (Mode)：\`${MODE_LABEL}\`"
log "Traceroute 目標 (Target)：\`${TARGET_DISPLAY}\`"
log "本地主機 (Local Host)：\`${LOCAL_IP} (${LOCAL_HOSTNAME})\`"

# ─── 1. 路徑追蹤 (Path to Public) ─────────────────────────
header "1. 路徑追蹤 (Path to Public Network)"
log "從本機 traceroute 至 \`${TARGET}\`，逐跳標記私有 (🏠) 與公網 (🌐)："

TR_OUTPUT=$(traceroute -n -m 20 -q 1 "$TARGET" 2>/dev/null)

PRIVATE_HOPS_STR=""
PUBLIC_ENTRY=""
PATH_RENDER=""
HOP_NUM=0
while read -r line; do
  HOP_NUM=$((HOP_NUM + 1))
  ip=$(echo "$line" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -n1)
  if [ -z "$ip" ]; then
    PATH_RENDER="${PATH_RENDER}  ${HOP_NUM}. * * *  (無回應 / no reply)\n"
    continue
  fi
  if is_private "$ip"; then
    PATH_RENDER="${PATH_RENDER}  ${HOP_NUM}. 🏠 ${ip}  (私有 private)\n"
    PRIVATE_HOPS_STR="${PRIVATE_HOPS_STR} ${ip}"
  else
    if [ -z "$PUBLIC_ENTRY" ]; then
      PUBLIC_ENTRY="$ip"
      PATH_RENDER="${PATH_RENDER}  ${HOP_NUM}. 🌐 ${ip}  (公網入口 PUBLIC ENTRY)\n"
    else
      PATH_RENDER="${PATH_RENDER}  ${HOP_NUM}. 🌐 ${ip}  (公網 public)\n"
    fi
  fi
done <<< "$(echo "$TR_OUTPUT" | awk 'NR>1')"

emit_block "$(echo -e "$PATH_RENDER")"
log ""
log "公網入口 (Public Entry)：\`${PUBLIC_ENTRY:-未偵測到 / not detected}\`"

# 蒐集私有網段去重 (本機網段 + 路徑上的私有 hop)
collect_private_nets() {
  local seen=" "
  # 本機所有私有網段
  while read -r ip; do
    [ -z "$ip" ] && continue
    if is_private "$ip"; then
      local net; net=$(echo "$ip" | cut -d. -f1-3)
      if [[ "$seen" != *" $net "* ]]; then echo "$net"; seen="$seen$net "; fi
    fi
  done <<< "$(ifconfig 2>/dev/null | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}')"
  # 路徑上的私有 hop 網段
  for ip in $PRIVATE_HOPS_STR; do
    local net; net=$(echo "$ip" | cut -d. -f1-3)
    if [[ "$seen" != *" $net "* ]]; then echo "$net"; seen="$seen$net "; fi
  done
}

# ─── --no-scan 模式到此結束 ───────────────────────────────
if [ "$DO_SCAN" = false ]; then
  header "完成 (Done — 路徑追蹤模式)"
  log "已跳過主動網段掃描 (--no-scan)。如需完整拓撲與風險評估，請移除 --no-scan 旗標。"
  log "\n═══════════════════════════════════════════════════════"
  log "報告儲存於：\`$REPORT_FILE\`"
  echo ""
  echo -e "${GREEN}✅ 完成！報告已儲存：$REPORT_FILE${NC}"
  exit 0
fi

# ─── 2. 網路拓撲 + 服務偵測 (Topology + Service Detection) ─
header "2. 網路拓撲與服務偵測 (Network Topology & Service Detection)"

PRIVATE_NETS=$(collect_private_nets)
log "待掃描私有網段 (Subnets to scan)：\`$(echo "$PRIVATE_NETS" | tr '\n' ' ')\`"

# 根據權限設定掃描參數
if [ "$(id -u)" -eq 0 ]; then
  SCAN_FLAGS="-sS -O -sV -F -T4 -n"
  log "（提示：目前以 root 權限執行，已啟用 OS 偵測與 SYN 掃描）"
else
  SCAN_FLAGS="-sV -F -T4 -n"
  log "（提示：非 root 執行，略過 OS 偵測；如需更完整結果可用 sudo）"
fi

# 累積資料: 拓撲樹 + findings 暫存檔
TOPO_RENDER="本地主機 (Local Host): ${LOCAL_IP} (${LOCAL_HOSTNAME})"
FINDINGS_FILE=$(mktemp)
TOTAL_HOSTS=0
TOTAL_SERVICES=0

NET_ARR=($PRIVATE_NETS)
NET_COUNT=${#NET_ARR[@]}
NET_IDX=0
for NETWORK_PREFIX in "${NET_ARR[@]}"; do
  NET_IDX=$((NET_IDX + 1))
  term_log "${YELLOW}正在掃描網段 ${NETWORK_PREFIX}.0/24 ...${NC}"

  if [ $NET_IDX -eq 1 ]; then
    TOPO_RENDER="${TOPO_RENDER}\n└── 子網 (Subnet): ${NETWORK_PREFIX}.0/24"
    NET_INDENT="    "
  else
    TOPO_RENDER="${TOPO_RENDER}\n${NET_INDENT}└── 子網 (Subnet): ${NETWORK_PREFIX}.0/24"
    NET_INDENT="${NET_INDENT}    "
  fi

  SCAN_OUTPUT=$(nmap $SCAN_FLAGS "${NETWORK_PREFIX}.0/24" 2>/dev/null)

  # 按主機分段 (Parse per-host blocks)
  declare -a HB_IP=() HB_DATA=()
  CUR_IP=""; CUR_BLOCK=""
  while IFS= read -r line; do
    if [[ $line =~ ^Nmap\ scan\ report\ for\ (.*) ]]; then
      [ -n "$CUR_IP" ] && { HB_IP+=("$CUR_IP"); HB_DATA+=("$CUR_BLOCK"); }
      CUR_IP="${BASH_REMATCH[1]}"; CUR_BLOCK="$line"
    elif [ -n "$CUR_IP" ]; then
      CUR_BLOCK="$CUR_BLOCK
$line"
    fi
  done <<< "$SCAN_OUTPUT"
  [ -n "$CUR_IP" ] && { HB_IP+=("$CUR_IP"); HB_DATA+=("$CUR_BLOCK"); }

  H_TOTAL=${#HB_IP[@]}
  for hi in "${!HB_IP[@]}"; do
    entry="${HB_IP[$hi]}"; details="${HB_DATA[$hi]}"
    if [[ $entry =~ (.*)\ \(([0-9.]+)\) ]]; then
      hname="${BASH_REMATCH[1]}"; a_ip="${BASH_REMATCH[2]}"
    else
      hname=""; a_ip="$entry"
    fi
    TOTAL_HOSTS=$((TOTAL_HOSTS + 1))

    if [ $((hi + 1)) -eq "$H_TOTAL" ] && [ $NET_IDX -eq "$NET_COUNT" ]; then
      H_PREFIX="└── "; S_INDENT="${NET_INDENT}    "
    else
      H_PREFIX="├── "; S_INDENT="${NET_INDENT}│   "
    fi

    HOST_DESC="$a_ip"; [ -n "$hname" ] && HOST_DESC="$HOST_DESC ($hname)"
    TOPO_RENDER="${TOPO_RENDER}\n${NET_INDENT}${H_PREFIX}${HOST_DESC}"

    # 開放服務 (Open services with version)
    SERVICES=$(echo "$details" | grep -E "^[0-9]+/[a-z]+" | grep "open")
    [ -z "$SERVICES" ] && continue
    S_COUNT=$(echo "$SERVICES" | wc -l | tr -d ' ')
    S_IDX=0
    while read -r s_line; do
      S_IDX=$((S_IDX + 1))
      TOTAL_SERVICES=$((TOTAL_SERVICES + 1))
      s_clean=$(echo "$s_line" | tr -s ' ')
      s_portproto=$(echo "$s_clean" | cut -d' ' -f1)   # e.g. 22/tcp
      s_port=$(echo "$s_portproto" | cut -d/ -f1)
      s_name=$(echo "$s_clean" | cut -d' ' -f3)
      s_version=$(echo "$s_clean" | cut -d' ' -f4-)

      [ $S_IDX -eq "$S_COUNT" ] && S_MARKER="└── " || S_MARKER="├── "
      svc_label="${s_portproto} (${s_name})"
      [ -n "$s_version" ] && svc_label="${svc_label} ${s_version}"
      TOPO_RENDER="${TOPO_RENDER}\n${S_INDENT}${S_MARKER}${svc_label}"

      # ── 風險判定 (Risk classification) ──
      hit=false
      pc=$(classify_port "$s_port" "$s_name")
      if [ -n "$pc" ]; then
        sev=$(echo "$pc" | cut -d'|' -f1); cat=$(echo "$pc" | cut -d'|' -f2)
        desc=$(echo "$pc" | cut -d'|' -f3); rem=$(echo "$pc" | cut -d'|' -f4)
        echo "${sev}|${a_ip}|${s_portproto}|${cat}|${desc}|${s_portproto} ${s_name} ${s_version}|${rem}" >> "$FINDINGS_FILE"
        hit=true
      fi
      vc=$(classify_version "$s_version")
      if [ -n "$vc" ]; then
        sev=$(echo "$vc" | cut -d'|' -f1); cat=$(echo "$vc" | cut -d'|' -f2)
        desc=$(echo "$vc" | cut -d'|' -f3); evi=$(echo "$vc" | cut -d'|' -f4); rem=$(echo "$vc" | cut -d'|' -f5)
        echo "${sev}|${a_ip}|${s_portproto}|${cat}|${desc}|${evi}|${rem}" >> "$FINDINGS_FILE"
        hit=true
      fi
      [ "$hit" = false ] && echo "INFO|${a_ip}|${s_portproto}|0|開放服務 ${s_name}|${s_portproto} ${s_name} ${s_version}|—" >> "$FINDINGS_FILE"
    done <<< "$SERVICES"
  done
  unset HB_IP HB_DATA
done

emit_block "$(echo -e "$TOPO_RENDER")"

# ─── 3. Executive Summary ─────────────────────────────────
header "3. Executive Summary"

count_sev() { grep "^$1|" "$FINDINGS_FILE" 2>/dev/null | wc -l | tr -d ' '; }
N_CRIT=$(count_sev CRIT); N_HIGH=$(count_sev HIGH)
N_MED=$(count_sev MED);   N_LOW=$(count_sev LOW); N_INFO=$(count_sev INFO)

log "| 指標 (Metric) | 數值 (Value) |"
log "| :--- | :--- |"
log "| 主機總數 (Total Hosts) | ${TOTAL_HOSTS} |"
log "| 服務總數 (Total Services) | ${TOTAL_SERVICES} |"
log "| 掃描網段數 (Subnets) | ${NET_COUNT} |"

log "\n風險分佈 (Risk Distribution):"
log "\n| 等級 (Severity) | 數量 (Count) |"
log "| :--- | :--- |"
log "| 🔴 Critical | ${N_CRIT} |"
log "| 🟠 High | ${N_HIGH} |"
log "| 🟡 Medium | ${N_MED} |"
log "| 🟢 Low | ${N_LOW} |"
log "| ℹ️ Info | ${N_INFO} |"

# ─── 4. 風險 Findings (Critical & High 優先) ──────────────
header "4. 風險 Findings (Critical & High Risk)"

emit_finding() {
  local sev_key="$1" sev_label="$2"
  local rows; rows=$(grep "^${sev_key}|" "$FINDINGS_FILE" 2>/dev/null)
  [ -z "$rows" ] && return
  while IFS='|' read -r sev host portproto cat desc evi rem; do
    log "\n#### ${sev_label} — ${host} ${portproto}\n"
    log "\n| 欄位 | 內容 |"
    log "| :--- | :--- |"
    log "| 主機 (Host) | \`${host}\` |"
    log "| 服務 (Service) | \`${portproto}\` |"
    log "| 風險類別 (Category) | ${cat} |"
    log "| 風險等級 (Severity) | ${sev_label} |"
    log "| 描述 (Description) | ${desc} |"
    log "| 判定依據 (Evidence) | \`${evi}\` |"
    log "| 建議修復 (Remediation) | ${rem} |"
  done <<< "$rows"
}

if [ "$N_CRIT" -eq 0 ] && [ "$N_HIGH" -eq 0 ]; then
  log "未發現 Critical 或 High 等級風險。✅"
else
  emit_finding CRIT "🔴 Critical"
  emit_finding HIGH "🟠 High"
fi

subheader "Medium 風險 (摘要)"
if [ "$N_MED" -eq 0 ]; then
  log "無 Medium 風險。"
else
  log "\n| 主機 | 服務 | 描述 |"
  log "| :--- | :--- | :--- |"
  while IFS='|' read -r sev host portproto cat desc evi rem; do
    log "| \`${host}\` | \`${portproto}\` | ${desc} |"
  done <<< "$(grep '^MED|' "$FINDINGS_FILE")"
fi

# ─── 5. 修復建議摘要 (Remediation Summary) ────────────────
header "5. 修復建議摘要 (Remediation Summary)"
if [ "$N_CRIT" -eq 0 ] && [ "$N_HIGH" -eq 0 ] && [ "$N_MED" -eq 0 ]; then
  log "目前無需優先處理項目。建議仍定期重新掃描以追蹤變化。"
else
  log "依嚴重度排序的行動清單 (Prioritized actions):"
  PRIORITY=1
  for sev in CRIT HIGH MED; do
    while IFS='|' read -r s host portproto cat desc evi rem; do
      [ -z "$host" ] && continue
      log "  ${PRIORITY}. \`${host}\` ${portproto} — ${rem}"
      PRIORITY=$((PRIORITY + 1))
    done <<< "$(grep "^${sev}|" "$FINDINGS_FILE")"
  done
fi

rm -f "$FINDINGS_FILE"

log "\n═══════════════════════════════════════════════════════"
log "掃描完成時間：\`$(date '+%Y-%m-%d %H:%M:%S')\`"
log "報告儲存於：\`$REPORT_FILE\`"
echo ""
echo -e "${GREEN}✅ 完成！報告已儲存：$REPORT_FILE${NC}"
