#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi

for arg in "$@"; do
    case "${arg}" in
        --help|-h)
            echo "Usage: $(basename "$0")"
            echo ""
            echo "執行全系統硬體與作業系統資訊探測，呈現聚合綜覽報告 (Consolidated System Overview)。"
            exit 0
            ;;
        *)
            echo "Error: unknown argument '${arg}'" >&2
            echo "Usage: $(basename "$0") [--help|-h]" >&2
            exit 1
            ;;
    esac
done

run_probe() {
    local script="$1"
    if [ -f "${script}" ]; then
        if ! "${script}"; then
            echo "Warning: probe $(basename "${script}") failed" >&2
        fi
    else
        echo "Warning: probe script not found: ${script}" >&2
    fi
}

echo "=================================================="
echo "系統資訊綜覽 (System Information Overview)"
echo "=================================================="
echo ""

run_probe "${SCRIPT_DIR}/os.sh"
echo ""

run_probe "${SCRIPT_DIR}/cpu.sh"
echo ""

run_probe "${SCRIPT_DIR}/memory.sh"
echo ""

run_probe "${SCRIPT_DIR}/gpu.sh"
echo ""

run_probe "${SCRIPT_DIR}/disk.sh"
echo ""

run_probe "${SCRIPT_DIR}/usb.sh"
echo ""

run_probe "${SCRIPT_DIR}/display.sh"
echo ""

run_probe "${SCRIPT_DIR}/network.sh"
echo ""

run_probe "${SCRIPT_DIR}/input.sh"
echo ""

run_probe "${SCRIPT_DIR}/audio.sh"
