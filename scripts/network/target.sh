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
使用方式: target.sh [CIDR] [選項]

探索指定 IPv4 CIDR 網段內的活躍主機 (Live Hosts)

引數:
  CIDR                  目標網段 (例如: 192.168.1.0/24；若省略則自動偵測本機區域網段)

選項:
  -h, --help            顯示此說明訊息
EOF
}

raw_target=""

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "錯誤: 未知選項 $1" >&2
            show_help >&2
            exit 1
            ;;
        *)
            if [ -z "$raw_target" ]; then
                raw_target="$1"
            fi
            shift
            ;;
    esac
done

detect_local_subnet() {
    local default_iface=""
    local local_ip=""
    local cidr=""

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
                cidr="$(ip -o -f inet addr show dev "$default_iface" 2>/dev/null | awk '{print $4}' | head -n 1 || true)"
            fi
            if [ -z "$cidr" ]; then
                cidr="$(ip -o -f inet addr show 2>/dev/null | awk '$2 != "lo" {print $4}' | head -n 1 || true)"
            fi
        fi
        if [ -z "$cidr" ] && command -v ifconfig >/dev/null 2>&1; then
            local_ip="$(ifconfig 2>/dev/null | awk '/inet / && $2 !~ /^127\./ {print $2; exit}' || true)"
        fi
    fi

    if [ -n "$cidr" ]; then
        local ip_part="${cidr%/*}"
        local mask_part="${cidr#*/}"
        local base_prefix="${ip_part%.*}"
        echo "${base_prefix}.0/${mask_part}"
    elif [ -n "$local_ip" ]; then
        local base_prefix="${local_ip%.*}"
        echo "${base_prefix}.0/24"
    else
        echo "192.168.1.0/24"
    fi
}

target="$raw_target"
if [ -z "$target" ]; then
    target="$(detect_local_subnet)"
fi

if [ "$target" = "192.168.0.0" ]; then
    target="192.168.0.0/16"
elif [[ "$target" != *"/"* ]]; then
    target="${target}/24"
fi

echo "正在掃描網路: ${target} (Scanning network...)"

if command -v nmap >/dev/null 2>&1; then
    while IFS="|" read -r ip hostname; do
        [ -z "$ip" ] && continue
        if [ -z "$hostname" ] || [ "$hostname" = "unknown" ]; then
            hostname="(未知/Unknown)"
        fi
        printf "✅ 發現主機: %s\t名稱: %s\n" "$ip" "$hostname"
    done < <(nmap -sn -T4 --min-parallelism 100 --max-retries 1 "$target" -oG - 2>/dev/null | sed -n 's/^Host: \([^ ]*\) (\([^)]*\)).*Status: Up.*$/\1|\2/p')
else
    if ! command -v ping >/dev/null 2>&1; then
        echo "錯誤: ping fallback is unavailable" >&2
        exit 1
    fi

    echo "未找到 nmap，改用 bounded ping fallback。"

    prefix_bits="${target#*/}"
    if [ "$prefix_bits" -lt 24 ]; then
        echo "錯誤: 掃描 ${target} 需要 nmap；ping fallback 僅支援 /24 或更小的網段 (Error: nmap is required to scan ${target}; ping fallback is limited to /24 or smaller networks)" >&2
        exit 1
    fi

    net_ip="${target%/*}"
    IFS='.' read -r a b c d <<< "$net_ip"
    base_prefix="${a}.${b}.${c}"

    start_host=1
    end_host=254
    if [ "$prefix_bits" -eq 32 ]; then
        start_host="$d"
        end_host="$d"
    else
        host_bits=$(( 32 - prefix_bits ))
        total_hosts=$(( 1 << host_bits ))
        net_start=$(( (d / total_hosts) * total_hosts ))
        if [ "$prefix_bits" -ge 31 ]; then
            start_host="$net_start"
            end_host=$(( net_start + total_hosts - 1 ))
        else
            start_host=$(( net_start + 1 ))
            end_host=$(( net_start + total_hosts - 2 ))
        fi
    fi

    tmp_file="$(mktemp)"
    trap 'rm -f "$tmp_file"' EXIT INT TERM

    worker_count=0
    for ((i=start_host; i<=end_host; i++)); do
        host_ip="${base_prefix}.${i}"
        (
            if [ "$OS" = "darwin" ]; then
                if ping -c 1 -W 1000 "$host_ip" >/dev/null 2>&1; then
                    echo "$host_ip" >> "$tmp_file"
                fi
            else
                if ping -c 1 -W 1 "$host_ip" >/dev/null 2>&1; then
                    echo "$host_ip" >> "$tmp_file"
                fi
            fi
        ) &
        worker_count=$(( worker_count + 1 ))
        if [ $(( worker_count % 32 )) -eq 0 ]; then
            wait
        fi
    done
    wait

    if [ -s "$tmp_file" ]; then
        while read -r ip; do
            [ -z "$ip" ] && continue
            printf "✅ 發現主機: %s\t名稱: %s\n" "$ip" "(未知/Unknown)"
        done < <(sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n "$tmp_file")
    fi
fi

echo "掃描完成。(Scan completed.)"
