#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi

OS="${OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

echo "音訊裝置 (Audio Devices)"

if [ "$OS" = "darwin" ]; then
    profiler_out=$(system_profiler SPAudioDataType 2>/dev/null || true)
    if [ -n "$profiler_out" ]; then
        echo "$profiler_out" | awk '
        /Devices:/ { in_devices = 1; next }
        in_devices {
            if ($0 ~ /^[[:space:]]{8}[A-Za-z0-9]/) {
                if (name != "") {
                    type_str = ""
                    if (out_ch != "") type_str = "Output"
                    if (in_ch != "") {
                        if (type_str != "") type_str = type_str "/Input"
                        else type_str = "Input"
                    }
                    default_str = ""
                    if (def_out ~ /Yes/) default_str = " [Default Output]"
                    if (def_in ~ /Yes/) default_str = default_str " [Default Input]"
                    ch_info = (out_ch != "" ? out_ch : in_ch)
                    printf "- %s: %s%s (Channels: %s%s, Transport: %s)\n", (type_str != "" ? type_str : "Audio"), name, default_str, (ch_info != "" ? ch_info : "N/A"), (rate != "" ? ", " rate " Hz" : ""), (transport != "" ? transport : "N/A")
                    count++
                }
                name = $0
                sub(/^[[:space:]]*/, "", name)
                sub(/:$/, "", name)
                out_ch = ""
                in_ch = ""
                def_out = ""
                def_in = ""
                transport = ""
                rate = ""
            }
            if ($0 ~ /Output Channels:/) { sub(/.*Output Channels:[[:space:]]*/, ""); out_ch = $0 }
            if ($0 ~ /Input Channels:/) { sub(/.*Input Channels:[[:space:]]*/, ""); in_ch = $0 }
            if ($0 ~ /Default Output Device:/) { sub(/.*Default Output Device:[[:space:]]*/, ""); def_out = $0 }
            if ($0 ~ /Default Input Device:/) { sub(/.*Default Input Device:[[:space:]]*/, ""); def_in = $0 }
            if ($0 ~ /Transport:/) { sub(/.*Transport:[[:space:]]*/, ""); transport = $0 }
            if ($0 ~ /Current SampleRate:/) { sub(/.*Current SampleRate:[[:space:]]*/, ""); rate = $0 }
        }
        END {
            if (name != "") {
                type_str = ""
                if (out_ch != "") type_str = "Output"
                if (in_ch != "") {
                    if (type_str != "") type_str = type_str "/Input"
                    else type_str = "Input"
                }
                default_str = ""
                if (def_out ~ /Yes/) default_str = " [Default Output]"
                if (def_in ~ /Yes/) default_str = default_str " [Default Input]"
                ch_info = (out_ch != "" ? out_ch : in_ch)
                printf "- %s: %s%s (Channels: %s%s, Transport: %s)\n", (type_str != "" ? type_str : "Audio"), name, default_str, (ch_info != "" ? ch_info : "N/A"), (rate != "" ? ", " rate " Hz" : ""), (transport != "" ? transport : "N/A")
                count++
            }
            if (count == 0) {
                print "未偵測到音訊裝置 (No audio devices detected)"
            }
        }'
    else
        echo "未偵測到音訊裝置 (No audio devices detected)"
    fi
else
    found=0
    # Output devices via aplay or pactl
    if command -v aplay >/dev/null 2>&1; then
        while read -r line; do
            [ -z "$line" ] && continue
            desc=$(echo "$line" | cut -d: -f2- | awk -F'\\[' '{print $1}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -n "$desc" ]; then
                echo "- Output: ${desc}"
                found=1
            fi
        done < <(aplay -l 2>/dev/null | grep "^card " || true)
    fi

    # Input devices via arecord
    if command -v arecord >/dev/null 2>&1; then
        while read -r line; do
            [ -z "$line" ] && continue
            desc=$(echo "$line" | cut -d: -f2- | awk -F'\\[' '{print $1}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -n "$desc" ]; then
                echo "- Input: ${desc}"
                found=1
            fi
        done < <(arecord -l 2>/dev/null | grep "^card " || true)
    fi

    # Fallback to pactl
    if [ "$found" -eq 0 ] && command -v pactl >/dev/null 2>&1; then
        while read -r desc; do
            [ -z "$desc" ] && continue
            echo "- Output: ${desc}"
            found=1
        done < <(pactl list sinks 2>/dev/null | awk -F': ' '/Description:/ {print $2}' || true)

        while read -r desc; do
            [ -z "$desc" ] && continue
            echo "- Input: ${desc}"
            found=1
        done < <(pactl list sources 2>/dev/null | awk -F': ' '/Description:/ {print $2}' || true)
    fi

    if [ "$found" -eq 0 ]; then
        echo "未偵測到音訊裝置 (No audio devices detected)"
    fi
fi
