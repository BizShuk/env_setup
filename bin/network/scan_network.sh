#!/bin/bash
# ==============================================================================
# scan_network — 統一網路掃描入口
# 取代舊 bin/scan_private_network, bin/scan_target_network, bin/system/network_topology_scan.sh
# ==============================================================================
# 整合三個重疊的掃描腳本為單一 dispatcher, 由 --mode 選擇子模式:
#   private         — 從本機往公網 traceroute, 對私有 hop 段做 nmap -F 掃描, 產出樹狀文字 (network.topo)
#   target          — 對指定 CIDR 跑 nmap -sn ping scan, 列出存活主機
#   topology        — 完整模式: traceroute + nmap -sV + 風險評估, 產出 markdown 報告
#   topology-no-scan— 只做 traceroute 路徑追蹤, 不主動發送 nmap 封包
#
# 用法 (Usage):
#   scan_network.sh --mode=private [target_ip]
#   scan_network.sh --mode=target [target_cidr]
#   scan_network.sh --mode=topology [--target <ip>]
#   scan_network.sh --mode=topology-no-scan [--target <ip>]
#   scan_network.sh -h|--help
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_BIN_SYSTEM="${SCRIPT_DIR%/network}/system"

MODE=""
TARGET=""

usage() {
    sed -n '2,24p' "$0"
    exit "${1:-0}"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --mode=*)
            MODE="${1#*=}"
            shift
            ;;
        --mode)
            MODE="${2:-}"
            shift 2
            ;;
        --target=*)
            TARGET="${1#*=}"
            shift
            ;;
        --target)
            TARGET="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage 0
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage 1
            ;;
        *)
            # 位置參數: 若 --mode=target 沒帶值, 第一個位置參數當 CIDR/target
            if [ -z "$TARGET" ]; then
                TARGET="$1"
            else
                echo "Too many positional arguments: $1" >&2
                usage 1
            fi
            shift
            ;;
    esac
done

if [ -z "$MODE" ]; then
    echo "ERROR: --mode is required (private|target|topology|topology-no-scan)" >&2
    usage 1
fi

# ---- 子模式: private (內聯自舊 bin/scan_private_network) -----------------
_scan_private() {
    local target="${1:-8.8.8.8}"

    # 顏色定義 (Color Definitions)
    local GREEN='\033[0;32m'
    local BLUE='\033[0;34m'
    local YELLOW='\033[1;33m'
    local NC='\033[0m'

    for cmd in traceroute nmap; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required dependency '$cmd' is not installed. Please install it first." >&2
            exit 1
        fi
    done

    local OUTPUT_FILE="network.topo"

    is_private() {
        local ip=$1
        if [[ $ip =~ ^10\. ]] ||
           [[ $ip =~ ^192\.168\. ]] ||
           [[ $ip =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]] ||
           [[ $ip =~ ^100\.(6[4-9]|[7-9][0-9]|1[0-1][0-9]|12[0-7])\. ]]; then
            return 0
        else
            return 1
        fi
    }

    echo -e "${YELLOW}正在分析網絡路徑... (Analyzing network path...)${NC}"

    get_local_ip() {
        if command -v ip &>/dev/null; then
            ip -o -4 addr show | awk '{print $4}' | cut -d/ -f1 | grep -v 127.0.0.1 | head -n1
        elif command -v ifconfig &>/dev/null; then
            ifconfig | grep "inet " | grep -v 127.0.0.1 | head -n1 | awk '{print $2}'
        else
            echo "127.0.0.1"
        fi
    }
    local LOCAL_IP
    LOCAL_IP=$(get_local_ip)
    local LOCAL_HOSTNAME
    LOCAL_HOSTNAME=$(hostname | sed 's/\.local$//')

    local LOCAL_NETS=""
    while read -r ip; do
        if [ -z "$ip" ]; then continue; fi
        if is_private "$ip"; then
            local net
            net=$(echo "$ip" | cut -d. -f1-3)
            if [[ ! "$LOCAL_NETS" =~ $net ]]; then
                LOCAL_NETS="$LOCAL_NETS $net"
            fi
        fi
    done <<< "$(
        if command -v ip &>/dev/null; then
            ip -o -4 addr show | awk '{print $4}' | cut -d/ -f1 | grep -v 127.0.0.1
        elif command -v ifconfig &>/dev/null; then
            ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
        fi
    )"

    echo -e "${YELLOW}正在追蹤路由... (Tracing route...)${NC}"
    local TR_OUTPUT
    TR_OUTPUT=$(traceroute -n -m 20 -q 1 "$target" 2>/dev/null)

    local PRIVATE_HOPS_STR=""
    while read -r line; do
        local ip
        ip=$(echo "$line" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -n1)
        if [ -n "$ip" ]; then
            if is_private "$ip"; then
                if [ -z "$PRIVATE_HOPS_STR" ]; then
                    PRIVATE_HOPS_STR="$ip"
                else
                    PRIVATE_HOPS_STR="$PRIVATE_HOPS_STR $ip"
                fi
            else
                break
            fi
        fi
    done <<< "$(echo "$TR_OUTPUT" | awk 'NR>1')"

    local PRIVATE_HOPS=($PRIVATE_HOPS_STR)

    for net in $LOCAL_NETS; do
        local in_path=false
        for hop in "${PRIVATE_HOPS[@]}"; do
            if [[ "$hop" == "$net".* ]]; then
                in_path=true
                break
            fi
        done
        if [ "$in_path" == "false" ]; then
            local l_ip
            if command -v ip &>/dev/null; then
                l_ip=$(ip -o -4 addr show | grep "$net" | awk '{print $4}' | cut -d/ -f1 | head -n1)
            elif command -v ifconfig &>/dev/null; then
                l_ip=$(ifconfig | grep "inet $net" | awk '{print $2}' | head -n1)
            else
                l_ip=""
            fi
            if [ -n "$l_ip" ]; then
                PRIVATE_HOPS=("$l_ip" "${PRIVATE_HOPS[@]}")
            fi
        fi
    done

    local REVERSED_HOPS=()
    for (( i=${#PRIVATE_HOPS[@]}-1; i>=0; i-- )); do
        REVERSED_HOPS+=("${PRIVATE_HOPS[i]}")
    done

    echo -e "${BLUE}偵測到 ${#REVERSED_HOPS[@]} 層私有網絡。正在掃描節點...${NC}"

    {
        echo "本地主機 (Local Host): $LOCAL_IP ($LOCAL_HOSTNAME)"

        local INDENT=""
        local LEVEL=1
        local NUM_LAYERS=${#REVERSED_HOPS[@]}

        for hop_ip in "${REVERSED_HOPS[@]}"; do
            local NETWORK_PREFIX
            NETWORK_PREFIX=$(echo "$hop_ip" | cut -d. -f1-3 | tr -d '[:space:]')

            if [ $LEVEL -eq 1 ]; then
                echo "└── 網路子網拓撲 (Network Subnet Topology): $NETWORK_PREFIX.0/24"
                INDENT="    "
            else
                echo "${INDENT}└── 網路子網拓撲 (Network Subnet Topology): $NETWORK_PREFIX.0/24"
                INDENT="$INDENT    "
            fi

            echo -e "${YELLOW}正在掃描網段 $NETWORK_PREFIX.0/24...${NC}" >&2

            local SCAN_FLAGS="-F -n"
            if [ "$EUID" -eq 0 ] || [ "$(id -u)" -eq 0 ]; then
                SCAN_FLAGS="$SCAN_FLAGS -O --osscan-limit"
            fi

            local FULL_SCAN_OUTPUT
            FULL_SCAN_OUTPUT=$(nmap $SCAN_FLAGS "$NETWORK_PREFIX.0/24")

            local NEXT_HOP_IP=""
            if [ $LEVEL -lt "$NUM_LAYERS" ]; then
                NEXT_HOP_IP="${REVERSED_HOPS[$LEVEL]}"
            fi

            declare -a HOST_BLOCKS_IP=()
            declare -a HOST_BLOCKS_DATA=()
            local CURRENT_IP=""
            local CURRENT_BLOCK=""

            while IFS= read -r line; do
                if [[ $line =~ ^Nmap\ scan\ report\ for\ (.*) ]]; then
                    if [ -n "$CURRENT_IP" ]; then
                        HOST_BLOCKS_IP+=("$CURRENT_IP")
                        HOST_BLOCKS_DATA+=("$CURRENT_BLOCK")
                    fi
                    CURRENT_IP="${BASH_REMATCH[1]}"
                    CURRENT_BLOCK="$line"
                elif [ -n "$CURRENT_IP" ]; then
                    CURRENT_BLOCK="$CURRENT_BLOCK
$line"
                fi
            done <<< "$FULL_SCAN_OUTPUT"
            if [ -n "$CURRENT_IP" ]; then
                HOST_BLOCKS_IP+=("$CURRENT_IP")
                HOST_BLOCKS_DATA+=("$CURRENT_BLOCK")
            fi

            local ACTUAL_INDICES=()
            for i in "${!HOST_BLOCKS_IP[@]}"; do
                local entry="${HOST_BLOCKS_IP[$i]}"
                local a_ip
                if [[ $entry =~ \(([0-9.]+)\) ]]; then
                    a_ip="${BASH_REMATCH[1]}"
                else
                    a_ip="$entry"
                fi
                if [ "$a_ip" != "$hop_ip" ] && [ "$a_ip" != "$NEXT_HOP_IP" ] && [ "$a_ip" != "127.0.0.1" ]; then
                    ACTUAL_INDICES+=($i)
                fi
            done

            local TOTAL_ACTUAL=${#ACTUAL_INDICES[@]}
            local IDX=0
            for i in "${ACTUAL_INDICES[@]}"; do
                IDX=$((IDX + 1))
                local entry="${HOST_BLOCKS_IP[$i]}"
                local HOST_DETAILS="${HOST_BLOCKS_DATA[$i]}"

                local hname a_ip
                if [[ $entry =~ (.*)\ \((.*)\) ]]; then
                    hname="${BASH_REMATCH[1]}"
                    a_ip="${BASH_REMATCH[2]}"
                else
                    hname=""
                    a_ip="$entry"
                fi
                local os_info
                os_info=$(echo "$HOST_DETAILS" | grep -E "OS details:|Running:" | head -n1 | cut -d: -f2- | sed 's/^ //')

                local H_PREFIX
                if [ $IDX -eq "$TOTAL_ACTUAL" ] && [ $LEVEL -eq "$NUM_LAYERS" ]; then
                    H_PREFIX="└── "
                else
                    H_PREFIX="├── "
                fi

                local HOST_DESC="$a_ip"
                [ -n "$hname" ] && HOST_DESC="$HOST_DESC ($hname)"
                [ -n "$os_info" ] && HOST_DESC="$HOST_DESC [$os_info]"

                echo "${INDENT}${H_PREFIX}${HOST_DESC}"

                local S_INDENT
                if [ "$H_PREFIX" == "└── " ]; then
                    S_INDENT="${INDENT}    "
                else
                    S_INDENT="${INDENT}│   "
                fi

                local SERVICES
                SERVICES=$(echo "$HOST_DETAILS" | grep -E "^[0-9]+/[a-z]+" | grep "open")
                if [ -n "$SERVICES" ]; then
                    local S_COUNT
                    S_COUNT=$(echo "$SERVICES" | wc -l | tr -d ' ')
                    local S_IDX=0
                    while read -r s_line; do
                        S_IDX=$((S_IDX + 1))
                        local s_clean
                        s_clean=$(echo "$s_line" | tr -s ' ')
                        local s_port s_name
                        s_port=$(echo "$s_clean" | cut -d' ' -f1)
                        s_name=$(echo "$s_clean" | cut -d' ' -f3)

                        local S_MARKER
                        if [ $S_IDX -eq "$S_COUNT" ]; then
                            S_MARKER="└── "
                        else
                            S_MARKER="├── "
                        fi

                        echo "${S_INDENT}${S_MARKER}${s_port} (${s_name})"
                    done <<< "$SERVICES"
                fi
            done

            unset HOST_BLOCKS_IP HOST_BLOCKS_DATA
            LEVEL=$((LEVEL + 1))
        done
    } > "$OUTPUT_FILE"

    echo "--------------------------------------------------"
    echo -e "${GREEN}分析完成！結果已儲存至: ${OUTPUT_FILE}${NC}"
    cat "$OUTPUT_FILE"
}

# ---- 子模式: target (內聯自舊 bin/scan_target_network) -------------------
_scan_target() {
    local target_range="${1:-192.168.0.0/24}"

    local GREEN='\033[0;32m'
    local BLUE='\033[0;34m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local NC='\033[0m'

    if [[ "$target_range" == "192.168.0.0" ]]; then
        target_range="192.168.0.0/16"
    fi

    echo -e "${YELLOW}正在掃描網絡: ${target_range}... (Scanning network...)${NC}"

    if ! command -v nmap &> /dev/null; then
        echo -e "${RED}錯誤: 未找到 nmap 命令。(Error: nmap not found.)${NC}"
        echo "正在嘗試使用基礎 ping 進行併發掃描 (嘗試簡單版本)..."
        for i in {1..254}; do
            (
                local IP="192.168.0.$i"
                if ping -c 1 -W 1 "$IP" &>/dev/null; then
                    echo -e "發現主機: ${GREEN}${IP}${NC}"
                fi
            ) &
        done
        wait
        return 0
    fi

    echo "--------------------------------------------------"
    echo -e "${BLUE}掃描模式: 高性能併發探索 (High-Performance Concurrent Scan)${NC}"
    echo -e "${BLUE}並行級別 (Parallelism): 自動優化 (Auto-optimized)${NC}"
    echo "--------------------------------------------------"

    nmap -sn -T4 --min-parallelism 100 --max-retries 1 "$target_range" -oG - | awk '/Up$/{print $2, $3}' | while read -r ip hostname; do
        hostname=${hostname//[()]/}
        if [ -n "$hostname" ] && [ "$hostname" != "unknown" ]; then
            echo -e "✅ 發現主機: ${GREEN}${ip}${NC} 	名稱: ${BLUE}${hostname}${NC}"
        else
            echo -e "✅ 發現主機: ${GREEN}${ip}${NC} 	名稱: ${YELLOW}(未知/Unknown)${NC}"
        fi
    done

    echo "--------------------------------------------------"
    echo -e "${GREEN}掃描完成。(Scan Completed.)${NC}"
}

# ---- dispatcher -----------------------------------------------------------
case "$MODE" in
    private)
        TARGET="${TARGET:-8.8.8.8}"
        _scan_private "$TARGET"
        ;;
    target)
        TARGET="${TARGET:-192.168.0.0/24}"
        _scan_target "$TARGET"
        ;;
    topology)
        exec "$REPO_BIN_SYSTEM/network_topology_scan.sh" ${TARGET:+--target "$TARGET"}
        ;;
    topology-no-scan)
        exec "$REPO_BIN_SYSTEM/network_topology_scan.sh" --no-scan ${TARGET:+--target "$TARGET"}
        ;;
    *)
        echo "ERROR: unknown mode '$MODE'. Use private|target|topology|topology-no-scan" >&2
        usage 1
        ;;
esac
