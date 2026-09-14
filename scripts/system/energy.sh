#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi

OS="${OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

INTERVAL=5
TOP_N=15
SORT_KEY="power"
TARGET_PID=""
DEEP=0

# 喚醒風暴判定門檻 (wakeup storm thresholds)
# 高 context switch 但低 CPU 是典型的 timer 密集行為: CPU 幾乎沒在做事,
# 卻不斷把核心從低耗電閒置狀態叫醒, 對電池的傷害遠大於 CPU 佔用本身.
# CPU 上限刻意壓低: 正在解碼影片或編譯的 process 本來就會有高 context switch,
# 那是有產出的工作, 不該與閒置空轉混為一談.
STORM_CSW_PER_SEC=200
STORM_CPU_PCT=5
STORM_IDLEW_PER_SEC=30

usage() {
    cat <<'EOF'
Usage: energy.sh [options]

分析 macOS 的耗電來源 (energy source), 重點在找出"喚醒密集但 CPU 佔用低"的
process: 這類 process 阻止 CPU 進入低耗電閒置狀態, 對電池的傷害不會顯示在
CPU 百分比上. 全部預設量測皆不需要 sudo.

Options:
  --interval SEC   取樣區間秒數, 決定速率的解析度 (default: 5)
  --top N          排行榜列出的 process 數量 (default: 15)
  --sort KEY       排序欄位: power | csw | idlew | cpu (default: power)
  --pid PID        單一 process 深入分析: 執行緒, 通訊端, 監看目錄, 子行程
  --deep           追加 powermetrics coalition 分析 (需要 sudo, 會提示輸入密碼)
  -h, --help       顯示本說明

Examples:
  ./energy.sh
  ./energy.sh --interval 10 --sort csw
  ./energy.sh --pid 49153
  ./energy.sh --deep
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --interval)
            INTERVAL="${2:-}"
            shift 2
            ;;
        --top)
            TOP_N="${2:-}"
            shift 2
            ;;
        --sort)
            SORT_KEY="${2:-}"
            shift 2
            ;;
        --pid)
            TARGET_PID="${2:-}"
            shift 2
            ;;
        --deep)
            DEEP=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: unknown argument '$1'" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ "$OS" != "darwin" ]; then
    echo "Error: energy.sh 只支援 macOS (darwin), 目前為 '${OS}'" >&2
    exit 1
fi

case "$SORT_KEY" in
    power|csw|idlew|cpu) ;;
    *)
        echo "Error: --sort 只接受 power | csw | idlew | cpu, 收到 '${SORT_KEY}'" >&2
        exit 1
        ;;
esac

if ! [ "$INTERVAL" -ge 1 ] 2>/dev/null; then
    echo "Error: --interval 必須是大於 0 的整數秒" >&2
    exit 1
fi

if ! [ "$TOP_N" -ge 1 ] 2>/dev/null; then
    echo "Error: --top 必須是大於 0 的整數" >&2
    exit 1
fi

if [ -n "$TARGET_PID" ]; then
    if ! [ "$TARGET_PID" -ge 1 ] 2>/dev/null; then
        echo "Error: --pid 必須是正整數" >&2
        exit 1
    fi
    # 先確認 process 存在, 否則取樣會得到空結果, 錯誤訊息會指錯方向.
    if ! ps -p "$TARGET_PID" >/dev/null 2>&1; then
        echo "Error: pid ${TARGET_PID} 不存在" >&2
        exit 1
    fi
fi

# top 的 delta 模式 (-c d) 會回報本次取樣區間內的增量,
# 因此 CSW 與 IDLEW 除以區間即為每秒速率; POWER 本身已是區間能耗指標.
sample_top() {
    # macOS 內建 bash 3.2 下, set -u 會把空陣列展開視為 unbound, 因此分兩條路徑呼叫.
    if [ -n "$TARGET_PID" ]; then
        top -l 2 -s "$INTERVAL" -c d -pid "$TARGET_PID" \
            -stats pid,command,cpu,csw,idlew,power 2>/dev/null || true
    else
        top -l 2 -s "$INTERVAL" -c d \
            -stats pid,command,cpu,csw,idlew,power 2>/dev/null || true
    fi
}

# 只取第二份取樣: 第一份沒有可比較的前次狀態, 速率欄位一律為 0.
parse_last_sample() {
    awk -v interval="$INTERVAL" '
    /^PID[[:space:]]/ { block++; next }
    block < 2 { next }
    NF >= 6 {
        pid = $1
        if (pid !~ /^[0-9]+$/) next
        power = $NF; idlew = $(NF-1); csw = $(NF-2); cpu = $(NF-3)
        gsub(/[^0-9.]/, "", power); gsub(/[^0-9.]/, "", idlew)
        gsub(/[^0-9.]/, "", csw);   gsub(/[^0-9.]/, "", cpu)
        cmd = ""
        for (i = 2; i <= NF-4; i++) cmd = (cmd == "" ? $i : cmd " " $i)
        if (cmd == "") cmd = "unknown"
        printf "%s\t%s\t%.1f\t%.1f\t%.1f\t%.1f\n", pid, cmd, cpu+0, csw/interval, idlew/interval, power+0
    }'
}

sort_rows() {
    local key="$1"
    local col
    case "$key" in
        cpu)   col=3 ;;
        csw)   col=4 ;;
        idlew) col=5 ;;
        power) col=6 ;;
    esac
    sort -t "$(printf '\t')" -k "${col}","${col}" -nr
}

print_power_state() {
    echo "電源狀態 (Power State)"

    local batt
    batt=$(pmset -g batt 2>/dev/null || true)
    local source_line
    source_line=$(echo "$batt" | sed -n "s/.*drawing from '\(.*\)'.*/\1/p" | head -1)
    echo "- Power Source: ${source_line:-unknown}"

    local charge
    charge=$(echo "$batt" | grep -oE '[0-9]+%' | head -1 || true)
    if [ -n "$charge" ]; then
        local state remaining
        state=$(echo "$batt" | sed -n 's/.*[0-9]*%; \([a-z ]*\);.*/\1/p' | head -1)
        remaining=$(echo "$batt" | grep -oE '[0-9]+:[0-9]+ remaining' | head -1 || true)
        echo "- Battery: ${charge}${state:+ (${state})}${remaining:+, ${remaining}}"
    fi

    local lpm
    lpm=$(pmset -g 2>/dev/null | awk '/lowpowermode/ {print $2; exit}' || true)
    if [ -n "$lpm" ]; then
        [ "$lpm" = "1" ] && echo "- Low Power Mode: on" || echo "- Low Power Mode: off"
    fi

    local sleep_line
    sleep_line=$(pmset -g 2>/dev/null | awk '/^ *sleep +/ {sub(/^ *sleep +/, ""); print; exit}' || true)
    [ -n "$sleep_line" ] && echo "- System Sleep: ${sleep_line}"

    local therm
    therm=$(pmset -g therm 2>/dev/null | grep -vE 'No (thermal|performance|CPU)' | head -3 || true)
    if [ -n "$therm" ]; then
        echo "- Thermal: 有紀錄的溫度或效能限制"
        echo "$therm" | awk '{ print "    " $0 }'
    fi
}

print_sleep_blockers() {
    echo "睡眠阻擋 (Sleep Blockers)"

    local assertions owners
    assertions=$(pmset -g assertions 2>/dev/null || true)
    owners=$(echo "$assertions" \
        | sed -n '/Listed by owning process/,$p' \
        | grep -E '^[[:space:]]*pid [0-9]+' || true)

    if [ -z "$owners" ]; then
        echo "- 無 process 持有睡眠阻擋 assertion"
        return
    fi

    echo "$owners" | while IFS= read -r line; do
        local who kind name
        who=$(echo "$line" | sed -n 's/.*pid \([0-9]*(\([^)]*\))\).*/\1/p')
        kind=$(echo "$line" | grep -oE '(NoIdleSleep|PreventUserIdleSystemSleep|PreventUserIdleDisplaySleep|PreventSystemSleep|BackgroundTask|NetworkClientActive)[A-Za-z]*' | head -1 || true)
        name=$(echo "$line" | sed -n 's/.*named: "\([^"]*\)".*/\1/p')
        echo "- ${who:-unknown}: ${kind:-assertion}${name:+ (${name})}"
    done
}

print_ranking() {
    local rows="$1"

    echo "耗能排行 (Top Energy Consumers, ${INTERVAL}s sample, sort=${SORT_KEY})"
    printf "%-8s %-24s %8s %10s %10s %8s\n" "PID" "COMMAND" "CPU%" "CSW/s" "IDLEW/s" "POWER"

    echo "$rows" | sort_rows "$SORT_KEY" | head -n "$TOP_N" | \
    while IFS=$'\t' read -r pid cmd cpu csw idlew power; do
        printf "%-8s %-24.24s %8s %10s %10s %8s\n" "$pid" "$cmd" "$cpu" "$csw" "$idlew" "$power"
    done
}

print_storms() {
    local rows="$1"

    echo "喚醒風暴 (Wakeup Storms)"
    echo "- 判定: CSW/s >= ${STORM_CSW_PER_SEC} 且 CPU% < ${STORM_CPU_PCT}, 或 IDLEW/s >= ${STORM_IDLEW_PER_SEC}"

    local hits
    hits=$(echo "$rows" | awk -F'\t' \
        -v csw_min="$STORM_CSW_PER_SEC" -v cpu_max="$STORM_CPU_PCT" -v idlew_min="$STORM_IDLEW_PER_SEC" '
        # kernel_task 的 idle wakeup 是全系統彙總而非它自己的行為, 列入只會固定誤報.
        $1 == 0 || $2 == "kernel_task" { next }
        ($4 >= csw_min && $3 < cpu_max) || $5 >= idlew_min { print }' | sort_rows csw || true)

    if [ -z "$hits" ]; then
        echo "- 目前沒有 process 觸發門檻"
        return
    fi

    echo "$hits" | head -n "$TOP_N" | while IFS=$'\t' read -r pid cmd cpu csw idlew power; do
        local ratio
        ratio=$(awk -v c="$csw" -v p="$cpu" 'BEGIN { printf "%.0f", c / (p > 0.1 ? p : 0.1) }')
        echo "- pid ${pid} (${cmd}): ${csw} csw/s, ${idlew} idlew/s, CPU ${cpu}%, 每 1% CPU 換來 ${ratio} 次喚醒"
    done

    echo "- 深入單一 process: $(basename "$0") --pid <PID>"
}

print_pid_detail() {
    local pid="$1"
    local rows="$2"

    echo "Process 概況 (Process Overview)"
    local full parent started rss threads
    full=$(ps -p "$pid" -o command= 2>/dev/null || true)
    parent=$(ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' ' || true)
    started=$(ps -p "$pid" -o etime= 2>/dev/null | tr -d ' ' || true)
    rss=$(ps -p "$pid" -o rss= 2>/dev/null | tr -d ' ' || true)
    threads=$(ps -M -p "$pid" 2>/dev/null | tail -n +2 | wc -l | tr -d ' ' || true)

    echo "- PID: ${pid}"
    echo "- Command: ${full:-unknown}"
    echo "- Parent PID: ${parent:-unknown}"
    echo "- Uptime: ${started:-unknown}"
    [ -n "$rss" ] && echo "- RSS: $(awk -v k="$rss" 'BEGIN { printf "%.0f MB", k / 1024 }')"
    echo "- Threads: ${threads:-unknown}"

    echo ""
    echo "喚醒速率 (Wakeup Rates, ${INTERVAL}s sample)"
    local row
    row=$(echo "$rows" | awk -F'\t' -v p="$pid" '$1 == p { print; exit }' || true)
    if [ -n "$row" ]; then
        local cpu csw idlew power
        cpu=$(echo "$row" | cut -f3)
        csw=$(echo "$row" | cut -f4)
        idlew=$(echo "$row" | cut -f5)
        power=$(echo "$row" | cut -f6)
        echo "- CPU: ${cpu}%"
        echo "- Context Switches: ${csw}/s"
        echo "- Idle Wakeups: ${idlew}/s"
        echo "- Energy Impact: ${power}"
        if [ -n "$threads" ] && [ "$threads" -gt 0 ] 2>/dev/null; then
            echo "- 每執行緒平均: $(awk -v c="$csw" -v t="$threads" 'BEGIN { printf "%.1f", c / t }') csw/s"
        fi
    else
        echo "- 取樣期間未取得資料, process 可能剛結束"
    fi

    local lsof_out=""
    if command -v lsof >/dev/null 2>&1; then
        lsof_out=$(lsof -nP -p "$pid" 2>/dev/null || true)
    fi

    echo ""
    echo "網路連線 (Network Endpoints)"
    if [ -z "$lsof_out" ]; then
        echo "- 無法讀取 (lsof 不可用或權限不足, 非本人 process 需要 sudo)"
    else
        local listen established
        listen=$(echo "$lsof_out" | grep -c 'LISTEN' || true)
        established=$(echo "$lsof_out" | grep -c 'ESTABLISHED' || true)
        echo "- Listening sockets: ${listen}"
        echo "- Established connections: ${established}"
        echo "$lsof_out" | awk '/LISTEN|ESTABLISHED/ { print "    " $(NF-1), $NF }' | sort -u | head -12
    fi

    echo ""
    echo "檔案監看 (File Watching)"
    if [ -z "$lsof_out" ]; then
        echo "- 無法讀取"
    else
        local dirs kqueues
        dirs=$(echo "$lsof_out" | awk '$5 == "DIR"' | wc -l | tr -d ' ' || true)
        kqueues=$(echo "$lsof_out" | grep -c 'KQUEUE' || true)
        echo "- Open directories: ${dirs} (kqueue 型 file watcher 每個監看目錄佔一個 fd)"
        echo "- KQUEUE descriptors: ${kqueues}"
    fi

    echo ""
    echo "子行程 (Child Processes)"
    local children
    children=$(ps -Ao pid,ppid,command 2>/dev/null | awk -v p="$pid" '$2 == p' || true)
    if [ -z "$children" ]; then
        echo "- 無子行程"
    else
        echo "$children" | awk '{ pid=$1; $1=""; $2=""; sub(/^  /, ""); printf "- %s: %.90s\n", pid, $0 }'
    fi
}

print_deep() {
    echo "Coalition 分析 (powermetrics, 需要 sudo)"

    if ! command -v powermetrics >/dev/null 2>&1; then
        echo "- powermetrics 不存在, 略過"
        return
    fi

    echo "- 執行 sudo powermetrics, 取樣 ${INTERVAL} 秒"
    local out
    if ! out=$(sudo powermetrics -n 1 -i "$((INTERVAL * 1000))" --samplers tasks \
        --show-process-coalition --show-process-energy 2>/dev/null); then
        echo "- powermetrics 執行失敗 (sudo 被拒或取消)"
        return
    fi

    echo "$out" | awk '
        /^Name .*ID .*CPU ms\/s/ { header = 1; print "    " $0; next }
        header && NF == 0 { exit }
        header { print "    " $0 }' | head -n "$((TOP_N + 6))"
}

echo "=================================================="
echo "能耗與喚醒分析 (Energy and Wakeup Analysis)"
echo "=================================================="
echo ""

print_power_state
echo ""
print_sleep_blockers
echo ""

ROWS="$(sample_top | parse_last_sample)"

if [ -z "$ROWS" ]; then
    echo "Error: top 未回傳可用的取樣資料" >&2
    exit 1
fi

if [ -n "$TARGET_PID" ]; then
    print_pid_detail "$TARGET_PID" "$ROWS"
else
    print_ranking "$ROWS"
    echo ""
    print_storms "$ROWS"
fi

if [ "$DEEP" -eq 1 ]; then
    echo ""
    print_deep
fi
