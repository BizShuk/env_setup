#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi

OS="${OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

show_help() {
    cat << 'EOF'
使用方式: private.sh [target] [選項]

追蹤路由路徑並產生私有網路跳點拓撲 (RFC 1918 / RFC 6598)

引數:
  target                追蹤目標 IPv4 位址 (預設: 8.8.8.8)

選項:
  -o, --output <file>   將拓撲結果另存至指定檔案
  -h, --help            顯示此說明訊息
EOF
}

target="8.8.8.8"
output_file=""

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -o|--output)
            if [ $# -lt 2 ]; then
                echo "錯誤: -o/--output 需要指定檔案路徑" >&2
                exit 1
            fi
            output_file="$2"
            shift 2
            ;;
        -*)
            echo "錯誤: 未知選項 $1" >&2
            show_help >&2
            exit 1
            ;;
        *)
            target="$1"
            shift
            ;;
    esac
done

if ! command -v traceroute >/dev/null 2>&1; then
    echo "錯誤: 找不到 'traceroute' 命令 (Error: 'traceroute' command not found)" >&2
    echo "請先安裝 traceroute (macOS: 系統內建；Linux: sudo apt-get install traceroute)" >&2
    exit 1
fi

hostname="$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "localhost")"
hostname="${hostname%.local}"

local_ip=""
if [ "$OS" = "darwin" ]; then
    default_iface="$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}' || true)"
    if [ -n "$default_iface" ]; then
        local_ip="$(ipconfig getifaddr "$default_iface" 2>/dev/null || true)"
    fi
    if [ -z "$local_ip" ]; then
        local_ip="$(ifconfig 2>/dev/null | awk '/inet / && $2 !~ /^127\./ {print $2; exit}' || true)"
    fi
else
    if command -v ip >/dev/null 2>&1; then
        default_iface="$(ip route show default 2>/dev/null | awk '/default via/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' | head -n 1 || true)"
        if [ -n "$default_iface" ]; then
            local_ip="$(ip -o -f inet addr show dev "$default_iface" 2>/dev/null | awk '{print $4}' | head -n 1 | cut -d/ -f1 || true)"
        fi
        if [ -z "$local_ip" ]; then
            local_ip="$(ip -o -f inet addr show 2>/dev/null | awk '$2 != "lo" {print $4}' | head -n 1 | cut -d/ -f1 || true)"
        fi
    fi
    if [ -z "$local_ip" ] && command -v ifconfig >/dev/null 2>&1; then
        local_ip="$(ifconfig 2>/dev/null | awk '/inet / && $2 !~ /^127\./ {print $2; exit}' || true)"
    fi
fi
local_ip="${local_ip:-127.0.0.1}"

is_private_ipv4() {
    local ip="$1"
    local a b c d
    IFS='.' read -r a b c d <<< "$ip"
    [[ "$a" =~ ^[0-9]+$ ]] && [[ "$b" =~ ^[0-9]+$ ]] && [[ "$c" =~ ^[0-9]+$ ]] && [[ "$d" =~ ^[0-9]+$ ]] || return 1
    [ "$a" -ge 0 ] && [ "$a" -le 255 ] || return 1
    [ "$b" -ge 0 ] && [ "$b" -le 255 ] || return 1
    [ "$c" -ge 0 ] && [ "$c" -le 255 ] || return 1
    [ "$d" -ge 0 ] && [ "$d" -le 255 ] || return 1

    # 10.0.0.0/8
    if [ "$a" -eq 10 ]; then return 0; fi
    # 172.16.0.0/12
    if [ "$a" -eq 172 ] && [ "$b" -ge 16 ] && [ "$b" -le 31 ]; then return 0; fi
    # 192.168.0.0/16
    if [ "$a" -eq 192 ] && [ "$b" -eq 168 ]; then return 0; fi
    # 100.64.0.0/10 (Carrier-Grade NAT)
    if [ "$a" -eq 100 ] && [ "$b" -ge 64 ] && [ "$b" -le 127 ]; then return 0; fi

    return 1
}

get_ipv4_subnet() {
    local ip="$1"
    local a b c d
    IFS='.' read -r a b c d <<< "$ip"
    echo "${a}.${b}.${c}.0/24"
}

echo "正在分析網路路徑... (Analyzing network path...)"

traceroute_raw="$(traceroute -n -q 1 -w 2 -m 30 "$target" 2>/dev/null || true)"

hop_records=()
while read -r line; do
    read -ra tokens <<< "$line"
    [ "${#tokens[@]}" -lt 2 ] && continue
    hop_num="${tokens[0]}"
    [[ "$hop_num" =~ ^[0-9]+$ ]] || continue

    hop_ip=""
    rtt=""
    for ((i=1; i<${#tokens[@]}; i++)); do
        token="${tokens[i]}"
        clean_token="${token#[}"
        clean_token="${clean_token%]}"
        clean_token="${clean_token#(}"
        clean_token="${clean_token%)}"
        if [[ "$clean_token" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            hop_ip="$clean_token"
            for ((j=i+1; j<${#tokens[@]}; j++)); do
                cand="${tokens[j]}"
                if [[ "$cand" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                    next_tok="${tokens[j+1]:-}"
                    if [[ "$next_tok" =~ ^ms ]]; then
                        rtt="${cand} ms"
                    else
                        rtt="${cand}"
                    fi
                    break
                fi
            done
            break
        fi
    done

    if [ -n "$hop_ip" ]; then
        if is_private_ipv4 "$hop_ip"; then
            hop_records+=("${hop_num}|${hop_ip}|${rtt}")
        else
            break
        fi
    fi
done <<< "$traceroute_raw"

render_topology() {
    echo "本地主機 (Local Host): ${local_ip} (${hostname})"
    if [ "${#hop_records[@]}" -eq 0 ]; then
        echo "└── 未發現私有路由跳點 (No private route hops found on route to ${target})"
        return
    fi

    local current_indent=""
    local last_subnet=""
    for item in "${hop_records[@]}"; do
        IFS='|' read -r h_num h_ip h_rtt <<< "$item"
        local subnet
        subnet="$(get_ipv4_subnet "$h_ip")"
        if [ "$subnet" != "$last_subnet" ]; then
            echo "${current_indent}└── 網路子網拓撲 (Network Subnet Topology): ${subnet}"
            current_indent="${current_indent}    "
            last_subnet="$subnet"
        fi
        if [ -n "$h_rtt" ]; then
            echo "${current_indent}└── 跳點 ${h_num} (Hop ${h_num}): ${h_ip} (${h_rtt})"
        else
            echo "${current_indent}└── 跳點 ${h_num} (Hop ${h_num}): ${h_ip}"
        fi
    done
}

topology_output="$(render_topology)"

if [ -n "$output_file" ]; then
    mkdir -p "$(dirname "$output_file")"
    echo "$topology_output" > "$output_file"
    echo "分析完成！結果已儲存至: ${output_file}"
    echo "$topology_output"
else
    echo "$topology_output"
    echo "分析完成。(Analysis completed.)"
fi
