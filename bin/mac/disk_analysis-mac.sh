#!/bin/bash
# ============================================================
#  Mac 磁碟使用分析腳本 (Mac Disk Usage Analysis Script)
#  使用方式：chmod +x disk_analysis-mac.sh && ./disk_analysis-mac.sh
#  旗標：
#    -c, --clean   分析完成後進入互動式清理（每輪先列清單與摘要再詢問 y/N）
#    -h, --help    顯示使用說明
# ============================================================

INTERACTIVE_CLEAN=false
for arg in "$@"; do
  case "$arg" in
    -c|--clean) INTERACTIVE_CLEAN=true ;;
    -h|--help)
      echo "使用方式：$0 [-c|--clean] [-h|--help]"
      echo "  -c, --clean   分析完成後進入互動式清理（逐輪詢問是否刪除）"
      echo "  -h, --help    顯示此說明"
      exit 0
      ;;
    *)
      echo "未知旗標：${arg}（可用：-c|--clean, -h|--help）" >&2
      exit 1
      ;;
  esac
done

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

REPORT_DIR="$HOME/.config/system/data"
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/disk_analysis-$(date +%Y%m%d).report.md"

# 終端輸出（帶顏色）
term_log() {
  echo -e "$1"
}

# 寫入 Markdown 檔案（移除 ANSI 轉義碼）
md_log() {
  echo -e "$1" | sed $'s/\033[[0-9;]*m//g' >> "$REPORT_FILE"
}

# 同時輸出
log() {
  term_log "$1"
  md_log "$1"
}

# 大標題
header() {
  term_log "\n${BOLD}${CYAN}════════════════${NC}"
  term_log "${BOLD}${CYAN}  $1${NC}"
  term_log "${BOLD}${CYAN}════════════════${NC}"
  
  md_log "\n# $1"
}

# 副標題
subheader() {
  term_log "\n${BOLD}${YELLOW}▶ $1${NC}"
  md_log "\n## $1"
}

md_code_block_start() {
  md_log "\`\`\`text"
}

md_code_block_end() {
  md_log "\`\`\`"
}

# 執行指令並包裝於 Markdown code block 內 (同步版本，防止 Race Condition)
run_cmd() {
  local cmd="$1"
  term_log "${CYAN}> $cmd${NC}"
  
  local cmd_out
  cmd_out=$(eval "$cmd" 2>&1)
  
  # 印在終端
  echo "$cmd_out"
  
  # 寫入 markdown
  # shellcheck disable=SC2001
  {
    echo ""
    echo "\`\`\`text"
    echo "$cmd_out" | sed $'s/\033[[0-9;]*m//g'
    echo "\`\`\`"
  } >> "$REPORT_FILE"
}

# 確保 Markdown 報告第一行即為 H1 標題，避免 MD041 錯誤
echo "# Mac 磁碟使用分析報告" > "$REPORT_FILE"
term_log "Mac 磁碟使用分析報告"

log "產生時間：\`$(date '+%Y-%m-%d %H:%M:%S')\`"
log "電腦名稱：\`$(hostname)\`"
log "使用者：\`$(whoami)\`"


# ─────────────────────────────────────────
header "1. 整體磁碟空間概覽 (Overall Disk Space)"
# ─────────────────────────────────────────
subheader "所有磁碟掛載點 (All Volumes)"
run_cmd 'df -h | grep -v "^map\|^devfs\|^drivefs"'

subheader "主磁碟詳情 (Main Disk Detail)"
run_cmd 'df -h /'

TOTAL=$(df -g / | awk 'NR==2{print $2}')
AVAIL=$(df -g / | awk 'NR==2{print $4}')
USED=$(df -g / | awk 'NR==2{print $3}')
log "\n主磁碟：共 \`${TOTAL}GB\`，已使用 \`${USED}GB\`，剩餘 \`${AVAIL}GB\`"

# ─────────────────────────────────────────
header "2. 主要目錄大小 (Top-Level Directory Sizes)"
# ─────────────────────────────────────────
subheader "家目錄各子目錄 (Home Directory Breakdown)"
run_cmd 'du -sh ~/*/ 2>/dev/null | sort -rh | head -20'

subheader "\`~/Library\` 各子目錄"
run_cmd 'du -sh ~/Library/*/ 2>/dev/null | sort -rh | head -15'

subheader "\`/Applications\` 各應用程式大小"
run_cmd 'du -sh /Applications/*.app 2>/dev/null | sort -rh | head -20'

# ─────────────────────────────────────────
header "3. 前 20 大檔案與資料夾 (Top 20 Largest Items)"
# ─────────────────────────────────────────
subheader "家目錄下前 20 大項目（排除系統保護路徑）"
run_cmd 'find ~ \( -path "*/Library/Containers/com.apple.Safari/Data/Library/Caches*" -o -path "*/.Trash*" \) -prune -o -maxdepth 8 -not -path "*/proc/*" -not -path "*/.git/*" -print 2>/dev/null | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head -20'

subheader "🔍 超過 5GB 的資料夾深度展開 (Drilldown: Folders > 5GB)"
# 對 Section 3 top-20 中任何 >5GB 的資料夾，再向下挖 2 層並列出前 15 大子項目
DRILLDOWN_THRESHOLD_KB=$((5 * 1024 * 1024))  # 5 GiB
# shellcheck disable=SC2016
big_items=$(find ~ \( -path "*/Library/Containers/com.apple.Safari/Data/Library/Caches*" -o -path "*/.Trash*" \) -prune -o -maxdepth 8 -type d -not -path "*/proc/*" -not -path "*/.git/*" -print 2>/dev/null \
  | xargs -I{} du -k -d 0 {} 2>/dev/null \
  | awk -F'\t' -v thr="$DRILLDOWN_THRESHOLD_KB" '$1 > thr { printf "%d\t%s\n", $1, $2 }' \
  | sort -rn \
  | head -15)
if [ -z "$big_items" ]; then
  log "（沒有超過 5GB 的資料夾）"
else
  echo "$big_items" | while IFS=$'\t' read -r size_k path; do
    # macOS 無 numfmt；以 awk 完成 KB → 人類可讀字串
    human=$(awk -v k="$size_k" 'BEGIN { if (k >= 1048576) printf "%.1fGB", k/1048576; else if (k >= 1024) printf "%dMB", k/1024; else printf "%dKB", k }')
    log "📂 \`$path\` — 合計 \`$human\`"
    md_code_block_start
    bd_out=$(du -h -d 2 "$path" 2>/dev/null | sort -hr | head -15)
    echo "$bd_out"
    echo "$bd_out" >> "$REPORT_FILE"
    md_code_block_end
  done
fi

# ─────────────────────────────────────────
header "4. 近期大型新增檔案 (Recently Added Large Files, last 60 days)"
# ─────────────────────────────────────────
subheader "過去 60 天內新增的大型檔案 (>50MB)"
run_cmd 'find ~ -maxdepth 8 -not -path "*/Library/CloudStorage*" -not -path "*/.git*" -newer ~/Library/Preferences/com.apple.finder.plist -size +50000k -type f 2>/dev/null | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head -30'

subheader "過去 60 天內修改的大型資料夾"
run_cmd 'find ~ -maxdepth 5 -not -path "*/Library/CloudStorage*" -not -path "*/.git*" -type d -newer ~/Library/Preferences/com.apple.finder.plist 2>/dev/null | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head -20'

# ─────────────────────────────────────────
header "5. ✅ 安全可刪除項目 (Safe-to-Delete Candidates)"
# ─────────────────────────────────────────

subheader "[快取 Caches] \`~/Library/Caches\`"
CACHE_SIZE=$(du -sh ~/Library/Caches 2>/dev/null | cut -f1)
log "總大小：\`${CACHE_SIZE}\`"
run_cmd 'find ~/Library/Caches -maxdepth 1 -mindepth 1 -type d -exec du -sh {} + 2>/dev/null | sort -rh | head -15'

subheader "[應用程式快取 App Caches] \`~/Library/Application Support\`"
run_cmd 'find ~/Library/"Application Support" -maxdepth 1 -mindepth 1 -type d -exec du -sh {} + 2>/dev/null | sort -rh | head -15'

subheader "[容器快取 Container Caches] \`~/Library/Containers\`"
run_cmd 'find ~/Library/Containers -maxdepth 1 -mindepth 1 -type d -exec du -sh {} + 2>/dev/null | sort -rh | head -15'

subheader "[群組容器快取 Group Container Caches] \`~/Library/Group Containers\`"
run_cmd 'find ~/Library/"Group Containers" -maxdepth 1 -mindepth 1 -type d -exec du -sh {} + 2>/dev/null | sort -rh | head -15'

subheader "[日誌 Logs]"
LOG_SIZE=$(du -sh ~/Library/Logs 2>/dev/null | cut -f1)
SYSLOG_SIZE=$(du -sh /private/var/log 2>/dev/null | cut -f1)
log "\`~/Library/Logs\` 大小：\`${LOG_SIZE}\`"
log "\`/private/var/log\` 大小：\`${SYSLOG_SIZE}\`"
run_cmd 'du -sh ~/Library/Logs/*/ 2>/dev/null | sort -rh | head -10'

subheader "[垃圾桶 Trash]"
TRASH_SIZE=$(du -sh ~/.Trash 2>/dev/null | cut -f1)
log "垃圾桶大小：\`${TRASH_SIZE}\`"
run_cmd 'ls -lah ~/.Trash 2>/dev/null | head -10'

subheader "[下載資料夾 Downloads]"
DL_SIZE=$(du -sh ~/Downloads 2>/dev/null | cut -f1)
log "Downloads 總大小：\`${DL_SIZE}\`"
log "\n前 20 大下載項目："
run_cmd 'du -sh ~/Downloads/* 2>/dev/null | sort -rh | head -20'
log "\n超過 60 天未存取的下載檔案："
run_cmd 'find ~/Downloads -maxdepth 2 -atime +60 -type f 2>/dev/null | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head -20'

subheader "[iOS/iPadOS 備份 iOS Backups]"
IOS_SIZE=$(du -sh ~/Library/Application\ Support/MobileSync/Backup 2>/dev/null | cut -f1)
log "iOS 備份大小：\`${IOS_SIZE}\`"
run_cmd 'ls -lah ~/Library/Application\ Support/MobileSync/Backup/ 2>/dev/null'

subheader "[Time Machine 快照 Local Snapshots]"
if tmutil listlocalsnapshots / &>/dev/null; then
  run_cmd 'tmutil listlocalsnapshots / 2>/dev/null'
else
  log "（無本機快照或需要管理員權限）"
fi

# ─────────────────────────────────────────
header "6. ⚠️  已知大型空間佔用者 (Known Space Hogs)"
# ─────────────────────────────────────────

subheader "[Docker] Docker 映像檔與磁碟映像"
if [ -d ~/Library/Containers/com.docker.docker ]; then
  DOCKER_SIZE=$(du -sh ~/Library/Containers/com.docker.docker 2>/dev/null | cut -f1)
  log "Docker 容器資料：\`${DOCKER_SIZE}\`"
fi
if [ -f ~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw ]; then
  DOCKER_RAW=$(du -sh ~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw 2>/dev/null | cut -f1)
  log "Docker 虛擬磁碟 (Docker.raw)：\`${DOCKER_RAW}\`"
fi
if [ -d ~/Library/Group\ Containers/group.com.docker ]; then
  run_cmd 'du -sh ~/Library/Group\ Containers/group.com.docker 2>/dev/null'
fi

subheader "[Colima] 虛擬機器與 Docker 資料磁碟 (Colima VM & Docker Data Disks)"
if [ -d ~/.colima ]; then
  COLIMA_SIZE=$(du -sh ~/.colima 2>/dev/null | cut -f1)
  log "Colima 總計（實際佔用）：\`${COLIMA_SIZE}\`"

  log "\n各子目錄實際佔用："
  run_cmd 'du -h -d 2 ~/.colima 2>/dev/null | sort -hr | head -10'

  log "\n稀疏檔案（宣告大小 apparent vs 實際佔用 actual）："
  log "註：datadisk = Docker 資料碟（images/volumes/containers），diffdisk = VM 系統碟可寫差異層（basedisk 為唯讀基底）。APFS 只分配實際寫入的區塊，故 apparent 遠大於 actual。"
  md_code_block_start
  sparse_out=$(find ~/.colima/_lima -type f -size +500M 2>/dev/null | while read -r f; do
    apparent=$(du -Ah "$f" | cut -f1)
    actual=$(du -h "$f" | cut -f1)
    echo "$f  (apparent: $apparent / actual: $actual)"
  done)
  echo "$sparse_out"
  echo "$sparse_out" >> "$REPORT_FILE"
  md_code_block_end

  COLIMA_SOCK="$HOME/.colima/default/docker.sock"
  if [ -S "$COLIMA_SOCK" ] && DOCKER_HOST="unix://$COLIMA_SOCK" docker info &>/dev/null; then
    export DOCKER_HOST="unix://$COLIMA_SOCK"

    log "\nDocker 內部用量（datadisk 組成，RECLAIMABLE 為可回收）："
    run_cmd 'docker system df'

    log "\nDocker 映像清單（in-use = 有容器使用中，unused = 可考慮 \`docker image prune -a\` 回收）："
    md_code_block_start
    used_ids=$(docker ps -a -q | xargs docker inspect --format '{{.Image}}' 2>/dev/null)
    img_out=$(docker images --no-trunc --format '{{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}' | while IFS=$'\t' read -r id name size; do
      if echo "$used_ids" | grep -q "$id"; then mark="in-use"; else mark="unused"; fi
      printf "%-7s %-55s %s\n" "$mark" "$name" "$size"
    done | sort -k1,1 -k2,2)
    echo "$img_out"
    echo "$img_out" >> "$REPORT_FILE"
    md_code_block_end

    unset DOCKER_HOST
  else
    log "（Colima 未執行，略過 Docker 內部用量與映像清單分析）"
  fi
else
  log "（未安裝 Colima）"
fi

subheader "[Xcode] 衍生資料與模擬器 (Derived Data & Simulators)"
XCODE_DD=$(du -sh ~/Library/Developer/Xcode/DerivedData 2>/dev/null | cut -f1)
XCODE_SIM=$(du -sh ~/Library/Developer/CoreSimulator 2>/dev/null | cut -f1)
XCODE_ARCH=$(du -sh ~/Library/Developer/Xcode/Archives 2>/dev/null | cut -f1)
log "Derived Data：\`${XCODE_DD}\`"
log "iOS Simulators：\`${XCODE_SIM}\`"
log "Archives（打包檔）：\`${XCODE_ARCH}\`"

subheader "[node_modules] JavaScript 依賴套件"
log "尋找所有 node_modules 資料夾（可能需要一些時間）..."
run_cmd 'find ~ -maxdepth 8 -name "node_modules" -type d -not -path "*/\.*" 2>/dev/null | xargs -I{} du -sh {} 2>/dev/null | sort -rh | head -20'

TOTAL_NM=$(find ~ -maxdepth 8 -name "node_modules" -type d -not -path "*/\.*" -print0 2>/dev/null | \
  xargs -0 du -s 2>/dev/null | awk '{sum+=$1} END {printf "%.1fGB\n", sum/1024/1024}')
log "node_modules 總計：\`${TOTAL_NM}\`"

subheader "[Python 虛擬環境 Python venvs & Conda]"
# shellcheck disable=SC2016
run_cmd 'find ~ -maxdepth 6 \( -name "pyvenv.cfg" -o -name "conda-meta" \) 2>/dev/null | while read f; do dir=$(dirname "$f"); du -sh "$dir" 2>/dev/null; done | sort -rh | head -10'

if [ -d ~/opt/anaconda3 ]; then
  CONDA_SIZE=$(du -sh ~/opt/anaconda3 2>/dev/null | cut -f1)
  log "Anaconda3：\`${CONDA_SIZE}\`"
fi
if [ -d ~/miniconda3 ]; then
  MINI_SIZE=$(du -sh ~/miniconda3 2>/dev/null | cut -f1)
  log "Miniconda3：\`${MINI_SIZE}\`"
fi

subheader "[Gradle 快取] Android/Java Build Caches"
GRADLE_SIZE=$(du -sh ~/.gradle 2>/dev/null | cut -f1)
log "\`~/.gradle\`：\`${GRADLE_SIZE}\`"
GRADLE_CACHE=$(du -sh ~/.gradle/caches 2>/dev/null | cut -f1)
log "\`~/.gradle/caches\`（可安全清除）：\`${GRADLE_CACHE}\`"

subheader "[虛擬機器磁碟映像 VM Disk Images]"
run_cmd 'find ~ -maxdepth 6 \( -name "*.vmdk" -o -name "*.vdi" -o -name "*.qcow2" -o -name "*.vhd" -o -name "*.parallels" -o -name "*.pvm" \) 2>/dev/null | xargs -I{} du -sh {} 2>/dev/null | sort -rh'

subheader "[Homebrew] 舊版套件快取"
if command -v brew &>/dev/null; then
  BREW_CACHE=$(du -sh "$(brew --cache)" 2>/dev/null | cut -f1)
  log "Homebrew 快取：\`${BREW_CACHE}\`"
  log "可執行 \`brew cleanup\` 清除舊版本"
else
  log "（未安裝 Homebrew）"
fi

subheader "[郵件 Mail] 附件與訊息快取"
MAIL_SIZE=$(du -sh ~/Library/Mail 2>/dev/null | cut -f1)
log "Apple Mail 資料：\`${MAIL_SIZE}\`"
MAIL_CACHE=$(du -sh ~/Library/Caches/com.apple.mail* 2>/dev/null | cut -f1)
log "Mail 快取：\`${MAIL_CACHE}\`"

subheader "[照片 Photos] 資料庫"
run_cmd 'find ~ -name "*.photoslibrary" -maxdepth 5 2>/dev/null | xargs -I{} du -sh {} 2>/dev/null | sort -rh'

subheader "[Spotlight 索引 & 臨時檔案]"
SPOTLIGHT=$(du -sh /.Spotlight-V100 2>/dev/null | cut -f1)
log "Spotlight 索引：\`${SPOTLIGHT}\`"

# ─────────────────────────────────────────
header "7. 重複檔案偵測提示 (Duplicate File Hints)"
# ─────────────────────────────────────────
log "在下列目錄尋找同名大型檔案（>100MB）："
md_code_block_start
# shellcheck disable=SC2016
dup_out=$(find ~/Downloads ~/Documents ~/Desktop -maxdepth 3 -size +100000k -type f 2>/dev/null | \
  awk -F'/' '{print $NF}' | sort | uniq -d | \
  while read -r fname; do
    echo "  重複檔名：$fname"
    find ~/Downloads ~/Documents ~/Desktop -maxdepth 3 -name "$fname" -print0 2>/dev/null | \
      xargs -0 -I{} du -sh {} 2>/dev/null
  done)
echo "$dup_out"
echo "$dup_out" >> "$REPORT_FILE"
md_code_block_end

# ─────────────────────────────────────────
header "8. 清理建議摘要 (Cleanup Recommendations)"
# ─────────────────────────────────────────

term_log "\n${GREEN}✅ 完全安全可刪除（不影響任何程式）:${NC}"
md_log "\n## \`✅ 完全安全可刪除（不影響任何程式）\`"
log "  1. 垃圾桶 (Trash)            → Finder > 清空垃圾桶"
log "  2. 應用程式快取 (App Caches)  → ~/Library/Caches 下各資料夾"
log "  3. 系統日誌 (Logs)            → ~/Library/Logs"
log "  4. Homebrew 舊版快取          → \`brew cleanup\`"
log "  5. 60+ 天未用的 Downloads 檔案 → 手動確認後刪除"
log "  6. Xcode Derived Data        → Xcode > Settings > Locations > 點垃圾桶"
log "  7. iOS Simulator 資料         → \`xcrun simctl delete unavailable\`"
log "  8. Gradle 快取                → \`rm -rf ~/.gradle/caches\`"

term_log "\n${YELLOW}⚠️  刪除前需確認（可能影響部分功能）:${NC}"
md_log "\n## \`⚠️  刪除前需確認（可能影響部分功能）\`"
log "  1. \`node_modules\`              → 只刪「不再開發」的專案（可 \`npm install\` 還原）"
log "  2. Python venv               → 只刪不再需要的虛擬環境"
log "  3. Docker 映像               → \`docker system prune\`（需重新 pull）"
log "  4. iOS 備份                  → 確認有 iCloud 備份再刪"
log "  5. Time Machine 快照          → \`tmutil deletelocalsnapshots /\`"

term_log "\n${RED}❌ 請勿輕易刪除:${NC}"
md_log "\n## \`❌ 請勿輕易刪除\`"
log "  1. \`~/Library/Application Support\`（可能含 App 重要設定與資料）"
log "  2. \`~/Library/Keychains\`（密碼鑰匙圈）"
log "  3. 照片資料庫（確認有備份再移除）"
log "  4. \`/System\`, \`/usr\`, \`/private\`（系統核心）"

# ─────────────────────────────────────────
header "9. 互動式一般清理 (Interactive General Cleanup)"
# ─────────────────────────────────────────

# 詢問 y/N（從 /dev/tty 讀取，避免被管線干擾）
ask_yn() {
  local prompt="$1" answer
  printf "%b" "${BOLD}${YELLOW}${prompt} [y/N] ${NC}" > /dev/tty
  read -r answer < /dev/tty
  [[ "$answer" =~ ^[Yy]$ ]]
}

# 每一輪：先顯示清理對象清單與大小摘要，再詢問是否執行
clean_round() {
  local title="$1" preview_cmd="$2" clean_cmd="$3"
  subheader "$title"
  run_cmd "$preview_cmd"
  if ask_yn "執行清理？(\`$clean_cmd\`)"; then
    local avail_before avail_after
    avail_before=$(df -k / | awk 'NR==2{print $4}')
    run_cmd "$clean_cmd"
    avail_after=$(df -k / | awk 'NR==2{print $4}')
    log "→ 已清理 (cleaned)，本輪釋放約 \`$(( (avail_after - avail_before) / 1024 ))MB\`"
  else
    log "→ 略過 (skipped)"
  fi
}

# Docker (Colima)：清單預覽（in-use/unused 標記）與清理
docker_unused_preview() {
  docker system df
  echo ""
  local used_ids id name size mark
  used_ids=$(docker ps -a -q | xargs docker inspect --format '{{.Image}}' 2>/dev/null)
  docker images --no-trunc --format '{{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}' | while IFS=$'\t' read -r id name size; do
    if echo "$used_ids" | grep -q "$id"; then mark="in-use"; else mark="unused"; fi
    printf "%-7s %-55s %s\n" "$mark" "$name" "$size"
  done | sort -k1,1 -k2,2
}

docker_unused_clean() {
  docker image prune -a -f
  docker builder prune -f
  # fstrim 將 VM 內已釋放的區塊還給 host 的稀疏檔案 (sparse file)
  command -v colima &>/dev/null && colima ssh -- sudo fstrim -a
}

if [ "$INTERACTIVE_CLEAN" != true ]; then
  log "（未指定 \`-c|--clean\` 旗標，略過互動式清理；執行 \`$0 --clean\` 可啟用）"
elif [ ! -t 0 ]; then
  log "（stdin 非 TTY，非互動模式，略過互動式清理）"
else
  CLEAN_AVAIL_START=$(df -g / | awk 'NR==2{print $4}')

  [ -d ~/.Trash ] && clean_round \
    "[Round 1] 垃圾桶 (Trash)" \
    'du -sh ~/.Trash 2>/dev/null; ls -A ~/.Trash 2>/dev/null | head -15' \
    'rm -rf ~/.Trash/* ~/.Trash/.[!.]* 2>/dev/null; true'

  clean_round \
    "[Round 2] 使用者快取 (~/Library/Caches)" \
    'du -sh ~/Library/Caches 2>/dev/null; du -sh ~/Library/Caches/* 2>/dev/null | sort -rh | head -10' \
    'rm -rf ~/Library/Caches/* 2>/dev/null; true'

  clean_round \
    "[Round 3] 使用者日誌 (~/Library/Logs)" \
    'du -sh ~/Library/Logs 2>/dev/null; du -sh ~/Library/Logs/* 2>/dev/null | sort -rh | head -10' \
    'rm -rf ~/Library/Logs/* 2>/dev/null; true'

  # shellcheck disable=SC2016
  command -v brew &>/dev/null && clean_round \
    "[Round 4] Homebrew 快取與舊版本" \
    'du -sh "$(brew --cache)" 2>/dev/null; brew cleanup -n 2>/dev/null | head -15' \
    'brew cleanup --prune=all'

  COLIMA_SOCK="$HOME/.colima/default/docker.sock"
  if [ -S "$COLIMA_SOCK" ] && DOCKER_HOST="unix://$COLIMA_SOCK" docker info &>/dev/null; then
    export DOCKER_HOST="unix://$COLIMA_SOCK"
    clean_round \
      "[Round 5] Docker 未使用映像與 Build Cache (Colima)" \
      'docker_unused_preview' \
      'docker_unused_clean'
    unset DOCKER_HOST
  fi

  [ -d ~/Library/Developer/Xcode/DerivedData ] && clean_round \
    "[Round 6] Xcode Derived Data" \
    'du -sh ~/Library/Developer/Xcode/DerivedData 2>/dev/null' \
    'rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null; true'

  [ -d ~/.gradle/caches ] && clean_round \
    "[Round 7] Gradle 快取 (~/.gradle/caches)" \
    'du -sh ~/.gradle/caches 2>/dev/null' \
    'rm -rf ~/.gradle/caches'

  CLEAN_AVAIL_END=$(df -g / | awk 'NR==2{print $4}')
  subheader "清理總結 (Cleanup Summary)"
  log "主磁碟剩餘空間：清理前 \`${CLEAN_AVAIL_START}GB\` → 清理後 \`${CLEAN_AVAIL_END}GB\`（共釋放約 \`$((CLEAN_AVAIL_END - CLEAN_AVAIL_START))GB\`）"
fi

log "\n═══════════════════════════════════════════════════════"
log "報告儲存於：\`$REPORT_FILE\`"
log "分析完成時間：\`$(date '+%Y-%m-%d %H:%M:%S')\`"
echo ""
echo -e "${GREEN}✅ 完成！報告已儲存：$REPORT_FILE${NC}"

