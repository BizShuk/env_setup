#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi

OS="${OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

echo "輸入裝置 (Input Devices)"

if [ "$OS" = "darwin" ]; then
    count=0

    # 1. Built-in input devices (Internal Keyboard / Trackpad)
    while read -r name; do
        [ -z "$name" ] && continue
        echo "- ${name} (Built-in)"
        count=$(( count + 1 ))
    done < <(ioreg -r -c AppleMultitouchDevice -d 1 2>/dev/null | awk -F'"' '/"Product" =/ {print $4}' | sort -u)

    # 2. Bluetooth connected input devices (Keyboards, Mice, Trackpads)
    bt_out=$(system_profiler SPBluetoothDataType 2>/dev/null || true)
    if [ -n "$bt_out" ]; then
        while read -r bt_dev; do
            [ -z "$bt_dev" ] && continue
            echo "- ${bt_dev} (Bluetooth)"
            count=$(( count + 1 ))
        done < <(echo "$bt_out" | awk '
        /Connected:/ { in_connected = 1; next }
        /Not Connected:/ { in_connected = 0 }
        in_connected {
            if ($0 ~ /^[[:space:]]{10}[A-Za-z0-9]/) {
                dev = $0
                sub(/^[[:space:]]*/, "", dev)
                sub(/:$/, "", dev)
            }
            if ($0 ~ /Minor Type:.*(Keyboard|Mouse|Trackpad|Peripheral)/) {
                if (dev != "") print dev
                dev = ""
            }
        }')
    fi

    # 3. USB input devices
    usb_out=$(system_profiler SPUSBDataType 2>/dev/null || true)
    if [ -n "$usb_out" ]; then
        while read -r usb_dev; do
            [ -z "$usb_dev" ] && continue
            if echo "$usb_dev" | grep -iE "(Keyboard|Mouse|Trackpad|Touchpad|HID|Receiver)" >/dev/null 2>&1; then
                echo "- ${usb_dev} (USB)"
                count=$(( count + 1 ))
            fi
        done < <(echo "$usb_out" | awk '
        NF > 0 {
            if ($0 ~ /Product ID:/) {
                sub(/:$/, "", prev)
                sub(/^[[:space:]]*/, "", prev)
                if (prev != "") print prev
            }
            prev = $0
        }')
    fi

    # 4. Fallback to SPInputDataType if count is still 0
    if [ "$count" -eq 0 ]; then
        input_out=$(system_profiler SPInputDataType 2>/dev/null || true)
        if [ -n "$input_out" ]; then
            while read -r dev; do
                [ -z "$dev" ] && continue
                echo "- ${dev}"
                count=$(( count + 1 ))
            done < <(echo "$input_out" | awk '
            NF > 0 {
                if ($0 ~ /Product ID:/) {
                    sub(/:$/, "", prev)
                    sub(/^[[:space:]]*/, "", prev)
                    if (prev != "") print prev
                }
                prev = $0
            }')
        fi
    fi

    if [ "$count" -eq 0 ]; then
        echo "未偵測到輸入裝置 (No input devices detected)"
    fi
else
    count=0
    if [ -f /proc/bus/input/devices ]; then
        while read -r line; do
            [ -z "$line" ] && continue
            name=$(echo "$line" | sed 's/^N: Name=//' | tr -d '"')
            # Filter out virtual event/beep devices if desired, or show relevant input names
            if echo "$name" | grep -iE "(keyboard|mouse|touchpad|trackpoint|pen|tablet)" >/dev/null 2>&1; then
                echo "- ${name}"
                count=$(( count + 1 ))
            fi
        done < <(grep "^N: Name=" /proc/bus/input/devices || true)
    fi

    if [ "$count" -eq 0 ] && command -v xinput >/dev/null 2>&1; then
        while read -r line; do
            [ -z "$line" ] && continue
            dev=$(echo "$line" | sed 's/^[[:space:]]*[↳⎜][[:space:]]*//' | awk -F'id=' '{print $1}' | sed 's/[[:space:]]*$//')
            if [ -n "$dev" ]; then
                echo "- ${dev}"
                count=$(( count + 1 ))
            fi
        done < <(xinput list --short 2>/dev/null | grep "slave  pointer\|slave  keyboard" || true)
    fi

    if [ "$count" -eq 0 ]; then
        echo "未偵測到輸入裝置 (No input devices detected)"
    fi
fi
