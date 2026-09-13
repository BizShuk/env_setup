#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi

OS="${OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

echo "處理器資訊 (CPU Information)"

if [ "$OS" = "darwin" ]; then
    brand=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)
    hw_model=$(sysctl -n hw.model 2>/dev/null || true)
    arch=$(uname -m)
    physical_cores=$(sysctl -n hw.physicalcpu 2>/dev/null || true)
    logical_cores=$(sysctl -n hw.logicalcpu 2>/dev/null || true)
    freq_hz=$(sysctl -n hw.cpufrequency 2>/dev/null || sysctl -n hw.cpufrequency_max 2>/dev/null || true)

    model="${brand:-${hw_model:-unknown}}"
    if [ -n "$hw_model" ] && [ "$hw_model" != "$model" ]; then
        model="${model} (${hw_model})"
    fi

    echo "- Model: ${model}"
    echo "- Architecture: ${arch}"
    if [ -n "$physical_cores" ]; then
        echo "- Physical Cores: ${physical_cores}"
    fi
    if [ -n "$logical_cores" ]; then
        echo "- Logical Cores: ${logical_cores}"
    fi

    if [ -n "$freq_hz" ] && [ "$freq_hz" -gt 0 ] 2>/dev/null; then
        freq_ghz=$(awk "BEGIN {printf \"%.2f GHz\", ${freq_hz} / 1000000000}")
        echo "- Frequency: ${freq_ghz}"
    else
        echo "- Frequency: Dynamic / N/A (Apple Silicon)"
    fi
else
    arch=$(uname -m)
    model=""
    logical_cores=""
    physical_cores=""
    freq=""

    if command -v lscpu >/dev/null 2>&1; then
        model=$(lscpu | grep -i "Model name:" | sed 's/Model name:[[:space:]]*//' || true)
        logical_cores=$(lscpu | grep -E "^CPU\(s\):" | awk '{print $2}' || true)
        sockets=$(lscpu | grep -i "Socket(s):" | awk '{print $2}' || true)
        cores_per_socket=$(lscpu | grep -i "Core(s) per socket:" | awk '{print $4}' || true)
        if [ -n "$sockets" ] && [ -n "$cores_per_socket" ]; then
            physical_cores=$(( sockets * cores_per_socket ))
        fi
        freq_mhz=$(lscpu | grep -i "CPU max MHz:" | awk '{print $4}' || true)
        if [ -z "$freq_mhz" ]; then
            freq_mhz=$(lscpu | grep -i "CPU MHz:" | awk '{print $3}' || true)
        fi
        if [ -n "$freq_mhz" ]; then
            freq="${freq_mhz} MHz"
        fi
    fi

    if [ -z "$model" ] && [ -f /proc/cpuinfo ]; then
        model=$(grep -m 1 -E "^(model name|Model)" /proc/cpuinfo | cut -d: -f2 | sed 's/^[[:space:]]*//' || true)
        if [ -z "$logical_cores" ]; then
            logical_cores=$(grep -c "^processor" /proc/cpuinfo || true)
        fi
        if [ -z "$freq" ]; then
            freq_mhz=$(grep -m 1 -i "cpu MHz" /proc/cpuinfo | cut -d: -f2 | sed 's/^[[:space:]]*//' || true)
            if [ -n "$freq_mhz" ]; then
                freq="${freq_mhz} MHz"
            fi
        fi
    fi

    echo "- Model: ${model:-unknown}"
    echo "- Architecture: ${arch}"
    if [ -n "$physical_cores" ]; then
        echo "- Physical Cores: ${physical_cores}"
    fi
    if [ -n "$logical_cores" ]; then
        echo "- Logical Cores: ${logical_cores}"
    fi
    if [ -n "$freq" ]; then
        echo "- Frequency: ${freq}"
    else
        echo "- Frequency: unknown"
    fi
fi
