#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi

OS="${OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

echo "正在偵測網絡介面... (Detecting network interfaces...)"
echo "--------------------------------------------------"

if [ "$OS" = "darwin" ]; then
    echo "作業系統 (OS): macOS (Darwin)"
    count=0
    seen_devices=""

    # 1. Hardware interfaces from networksetup
    if command -v networksetup >/dev/null 2>&1; then
        while IFS="|" read -r port dev mac; do
            [ -z "$dev" ] && continue
            seen_devices="${seen_devices} ${dev}"
            ip=$(ipconfig getifaddr "$dev" 2>/dev/null || true)
            status=$(ifconfig "$dev" 2>/dev/null | awk '/status:/ {print $2}' || true)
            if [ -n "$ip" ] || [ "$status" = "active" ]; then
                mac_real=$(ifconfig "$dev" 2>/dev/null | awk '/ether / {print $2}' || true)
                mac_display="${mac_real:-${mac:-N/A}}"
                echo "${port} (${dev}): ${ip:-No IPv4} (MAC: ${mac_display}, Status: ${status:-inactive})"
                count=$(( count + 1 ))
            fi
        done < <(networksetup -listallhardwareports 2>/dev/null | awk '
        /Hardware Port:/ { sub(/Hardware Port:[[:space:]]*/, ""); port=$0 }
        /Device:/ { sub(/Device:[[:space:]]*/, ""); dev=$0 }
        /Ethernet Address:/ {
            sub(/Ethernet Address:[[:space:]]*/, ""); mac=$0
            print port "|" dev "|" mac
        }')
    fi

    # 2. Any additional active interfaces with IPv4 (e.g. VPN, bridge, VLAN)
    while read -r line; do
        [ -z "$line" ] && continue
        dev=$(echo "$line" | awk '{print $1}')
        ip=$(echo "$line" | awk '{print $2}')
        # Check if already seen
        case " ${seen_devices} " in
            *" ${dev} "*) continue ;;
        esac
        mac=$(ifconfig "$dev" 2>/dev/null | awk '/ether / {print $2}' || echo "N/A")
        status=$(ifconfig "$dev" 2>/dev/null | awk '/status:/ {print $2}' || echo "active")
        echo "其他介面 (${dev}): ${ip} (MAC: ${mac}, Status: ${status})"
        count=$(( count + 1 ))
    done < <(ifconfig 2>/dev/null | awk '
    /^[a-z0-9]+:/ { iface = substr($1, 1, length($1)-1) }
    /inet / { if ($2 !~ /^127\./) print iface " " $2 }
    ')

    if [ "$count" -eq 0 ]; then
        echo "未發現作用中的網路介面 (No active network interfaces found)"
    fi
else
    echo "作業系統 (OS): Linux"
    count=0

    if command -v ip >/dev/null 2>&1; then
        while read -r dev status ip mac; do
            [ -z "$dev" ] && continue
            if [ "$dev" = "lo" ]; then continue; fi

            # Classify label
            case "$dev" in
                wl*) label="WiFi (${dev})" ;;
                eth*|en*) label="區域網路 (${dev})" ;;
                *) label="其他介面 (${dev})" ;;
            esac

            echo "${label}: ${ip:-No IPv4} (MAC: ${mac:-N/A}, Status: ${status})"
            count=$(( count + 1 ))
        done < <(ip -br addr show 2>/dev/null | while read -r iface state addrs; do
            if [ "$state" = "UP" ]; then
                ipv4=$(echo "$addrs" | tr ' ' '\n' | grep -v ':' | head -n 1 | cut -d/ -f1 || true)
                mac=$(ip link show "$iface" 2>/dev/null | awk '/link\/ether/ {print $2}' || true)
                echo "$iface" "$state" "${ipv4:-}" "${mac:-N/A}"
            fi
        done)
    elif command -v ifconfig >/dev/null 2>&1; then
        while read -r dev ip; do
            mac=$(ifconfig "$dev" 2>/dev/null | awk '/ether|HWaddr/ {print $2}' || echo "N/A")
            echo "介面 (${dev}): ${ip} (MAC: ${mac})"
            count=$(( count + 1 ))
        done < <(ifconfig 2>/dev/null | awk '
        /^[a-z0-9]+:/ { iface = substr($1, 1, length($1)-1) }
        /inet / { if ($2 !~ /^127\./) print iface " " $2 }
        ')
    fi

    if [ "$count" -eq 0 ]; then
        echo "未發現作用中的網路介面 (No active network interfaces found)"
    fi
fi

echo "--------------------------------------------------"
