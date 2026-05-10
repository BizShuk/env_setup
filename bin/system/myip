#!/bin/bash

# ==============================================================================
# Script Name: get_ip
# Description: 顯示 WiFi 和區域網路 (LAN) 的 IP 地址 (Show IP addresses for WiFi and LAN)
# OS Support: macOS (Darwin) 和 Linux
# ==============================================================================

# 顏色定義 (Color Definitions)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}正在偵測網絡介面... (Detecting network interfaces...)${NC}"
echo "--------------------------------------------------"

OS_TYPE=$(uname -s)

if [ "$OS_TYPE" == "Darwin" ]; then
    # macOS 系統
    echo -e "${BLUE}作業系統 (OS): macOS (Darwin)${NC}"

    # 获取所有硬件端口信息 (Get all hardware ports info)
    # 使用 networksetup 找到 WiFi 和 Ethernet 接口
    PORTS_INFO=$(networksetup -listallhardwareports)

    # 提取所有介面及其類型 (Extract all interfaces and their types)
    # 我們遍歷所有 Hardware Port
    echo "$PORTS_INFO" | grep "Hardware Port:" | while read -r line; do
        PORT_NAME=$(echo "$line" | cut -d: -f2- | sed 's/^ //')
        DEVICE=$(echo "$PORTS_INFO" | grep -A 1 "$line" | grep "Device:" | awk '{print $2}')

        if [ -n "$DEVICE" ]; then
            IP_ADDR=$(ipconfig getifaddr "$DEVICE")

            # 判斷類型 (Determine Type)
            if [[ "$PORT_NAME" =~ "Wi-Fi" ]] || [[ "$PORT_NAME" =~ "AirPort" ]]; then
                TYPE="WiFi"
            elif [[ "$PORT_NAME" =~ "Ethernet" ]] || [[ "$PORT_NAME" =~ "LAN" ]] || [[ "$PORT_NAME" =~ "Thunderbolt" ]]; then
                TYPE="區域網路 (LAN)"
            else
                TYPE="其他 (Other) [$PORT_NAME]"
            fi

            if [ -n "$IP_ADDR" ]; then
                echo -e "${TYPE} (${DEVICE}): ${GREEN}${IP_ADDR}${NC}"
            fi
        fi
    done

elif [ "$OS_TYPE" == "Linux" ]; then
    # Linux 系統
    echo -e "${BLUE}作業系統 (OS): Linux${NC}"

    # 獲取所有具備 IPv4 的介面 (Get all interfaces with IPv4)
    # 排除 loopback (lo)
    INTERFACES=$(ip -4 -o addr show | awk '$2 != "lo" {print $2}' | sort -u)

    for IFACE in $INTERFACES; do
        IP_ADDR=$(ip -4 -o addr show "$IFACE" | awk '{print $4}' | cut -d/ -f1 | head -n1)

        # 判斷是 WiFi 還是 LAN
        # 1. 檢查是否存在 wireless 次目錄
        if [ -d "/sys/class/net/$IFACE/wireless" ] || [ -d "/sys/class/net/$IFACE/phy80211" ]; then
            TYPE="WiFi"
        # 2. 依照名稱慣例
        elif [[ $IFACE == w* ]]; then
            TYPE="WiFi"
        elif [[ $IFACE == e* ]] || [[ $IFACE == eth* ]]; then
            TYPE="區域網路 (LAN)"
        else
            TYPE="其他 (Other)"
        fi

        echo -e "${TYPE} (${IFACE}): ${GREEN}${IP_ADDR}${NC}"
    done
else
    echo -e "${YELLOW}不支援的作業系統 (Unsupported OS): $OS_TYPE${NC}"
    # 退而求其次，嘗試通用命令 (Fallback to generic command)
    if command -v hostname > /dev/null; then
        echo "嘗試獲取 IP: $(hostname -I)"
    fi
fi

echo "--------------------------------------------------"
