#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi

OS="${OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

echo "顯示卡 (GPU)"

if [ "$OS" = "darwin" ]; then
    profiler_out=$(system_profiler SPDisplaysDataType 2>/dev/null || true)

    if [ -n "$profiler_out" ]; then
        echo "$profiler_out" | awk '
        /Chipset Model:/ { sub(/.*Chipset Model:[[:space:]]*/, ""); chipset=$0 }
        /Total Number of Cores:/ { sub(/.*Total Number of Cores:[[:space:]]*/, ""); cores=$0 }
        /Vendor:/ { sub(/.*Vendor:[[:space:]]*/, ""); vendor=$0 }
        /Metal Support:/ { sub(/.*Metal Support:[[:space:]]*/, ""); metal=$0 }
        /VRAM/ { sub(/.*VRAM[^:]*:[[:space:]]*/, ""); vram=$0 }
        END {
            model = (chipset != "" ? chipset : "unknown")
            printf "- GPU Model: %s\n", model
            if (vendor != "") printf "- Vendor: %s\n", vendor
            if (cores != "")  printf "- Cores: %s\n", cores
            if (vram != "")   printf "- VRAM: %s\n", vram
            else if (model ~ /^Apple/) printf "- VRAM: Unified Memory\n"
            if (metal != "")  printf "- Metal Support: %s\n", metal
        }'
    else
        echo "- GPU Model: unknown"
    fi
else
    found=0
    if command -v nvidia-smi >/dev/null 2>&1; then
        smi_out=$(nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader,nounits 2>/dev/null || true)
        if [ -n "$smi_out" ]; then
            while IFS=',' read -r name mem driver; do
                name_clean=$(echo "$name" | xargs)
                mem_clean=$(echo "$mem" | xargs)
                driver_clean=$(echo "$driver" | xargs)
                echo "- GPU Model: ${name_clean}"
                echo "- VRAM: ${mem_clean} MiB"
                echo "- Driver: ${driver_clean}"
                found=1
            done <<< "$smi_out"
        fi
    fi

    if [ "$found" -eq 0 ] && command -v lspci >/dev/null 2>&1; then
        while read -r line; do
            [ -z "$line" ] && continue
            gpu_desc=$(echo "$line" | cut -d: -f3- | sed 's/^[[:space:]]*//')
            echo "- GPU Model: ${gpu_desc}"
            found=1
        done < <(lspci 2>/dev/null | grep -E "(VGA compatible controller|3D controller|Display controller)" || true)
    fi

    if [ "$found" -eq 0 ]; then
        echo "- GPU Model: unknown"
    fi
fi
