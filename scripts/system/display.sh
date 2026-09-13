#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi

OS="${OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

echo "顯示器 (Display)"

if [ "$OS" = "darwin" ]; then
    profiler_out=$(system_profiler SPDisplaysDataType 2>/dev/null || true)

    if [ -n "$profiler_out" ]; then
        echo "$profiler_out" | awk '
        /Displays:/ { in_displays = 1; next }
        in_displays {
            if ($0 ~ /^[[:space:]]{8}[A-Za-z0-9]/) {
                if (disp_name != "") {
                    printf "- Display: %s\n", disp_name
                    printf "    Resolution: %s\n", (res != "" ? res : "unknown")
                    printf "    Connection: %s\n", (conn != "" ? conn : "N/A")
                    if (disp_type != "") printf "    Type: %s\n", disp_type
                    count++
                }
                disp_name = $0
                sub(/^[[:space:]]*/, "", disp_name)
                sub(/:$/, "", disp_name)
                res = ""
                conn = ""
                disp_type = ""
            }
            if ($0 ~ /Resolution:/) { sub(/.*Resolution:[[:space:]]*/, ""); res = $0 }
            if ($0 ~ /Connection Type:/) { sub(/.*Connection Type:[[:space:]]*/, ""); conn = $0 }
            if ($0 ~ /Display Type:/) { sub(/.*Display Type:[[:space:]]*/, ""); disp_type = $0 }
        }
        END {
            if (disp_name != "") {
                printf "- Display: %s\n", disp_name
                printf "    Resolution: %s\n", (res != "" ? res : "unknown")
                printf "    Connection: %s\n", (conn != "" ? conn : "N/A")
                if (disp_type != "") printf "    Type: %s\n", disp_type
                count++
            }
            if (count == 0) {
                print "未偵測到顯示器 (No displays detected)"
            }
        }'
    else
        echo "未偵測到顯示器 (No displays detected)"
    fi
else
    found=0
    if command -v xrandr >/dev/null 2>&1; then
        while read -r name status rest; do
            if [ "$status" = "connected" ]; then
                res=$(echo "$rest" | grep -oE "[0-9]+x[0-9]+\+[0-9]+\+[0-9]+" | head -n 1 || echo "")
                if [ -z "$res" ]; then
                    res=$(echo "$rest" | grep -oE "[0-9]+x[0-9]+" | head -n 1 || echo "unknown")
                fi
                echo "- Display: ${name}"
                echo "    Resolution: ${res}"
                echo "    Connection: ${name}"
                found=1
            fi
        done < <(xrandr --current 2>/dev/null | grep -w "connected" || true)
    fi

    if [ "$found" -eq 0 ] && [ -d /sys/class/drm ]; then
        for connector in /sys/class/drm/card*-*; do
            if [ -f "${connector}/status" ] && grep -q "^connected" "${connector}/status" 2>/dev/null; then
                c_name=$(basename "${connector}" | sed 's/^card[0-9]*-//')
                res="unknown"
                if [ -f "${connector}/modes" ]; then
                    res=$(head -n 1 "${connector}/modes" || echo "unknown")
                fi
                echo "- Display: ${c_name}"
                echo "    Resolution: ${res}"
                echo "    Connection: ${c_name}"
                found=1
            fi
        done
    fi

    if [ "$found" -eq 0 ] && command -v xdpyinfo >/dev/null 2>&1; then
        res=$(xdpyinfo 2>/dev/null | awk '/dimensions:/ {print $2}' || true)
        if [ -n "$res" ]; then
            echo "- Display: Default Screen"
            echo "    Resolution: ${res}"
            echo "    Connection: X11"
            found=1
        fi
    fi

    if [ "$found" -eq 0 ]; then
        echo "未偵測到顯示器 (No displays detected)"
    fi
fi
