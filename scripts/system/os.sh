#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi

OS="${OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

echo "系統概況 (System Overview)"

now_str=$(date "+%Y-%m-%d %H:%M:%S %z")
kernel_info=$(uname -mrs 2>/dev/null || uname -a)
host_name=$(hostname 2>/dev/null || echo "unknown")
uptime_info=$(uptime 2>/dev/null | sed 's/^[[:space:]]*//' || echo "unknown")

if [ "$OS" = "darwin" ]; then
    product_name=$(sw_vers -productName 2>/dev/null || echo "macOS")
    product_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
    build_version=$(sw_vers -buildVersion 2>/dev/null || echo "")
    arch=$(uname -m)

    os_desc="${product_name} ${product_version} (${arch})"
    if [ -n "$build_version" ]; then
        os_desc="${os_desc} [Build ${build_version}]"
    fi

    echo "- OS: ${os_desc}"
    echo "- Kernel: ${kernel_info}"
    echo "- Hostname: ${host_name}"
    echo "- Uptime: ${uptime_info}"
    echo "- Date: ${now_str}"
else
    arch=$(uname -m)
    distro=""
    if [ -f /etc/os-release ]; then
        distro=$(grep -E "^PRETTY_NAME=" /etc/os-release | cut -d= -f2 | tr -d '"' || true)
        if [ -z "$distro" ]; then
            distro_name=$(grep -E "^NAME=" /etc/os-release | cut -d= -f2 | tr -d '"' || true)
            distro_ver=$(grep -E "^VERSION=" /etc/os-release | cut -d= -f2 | tr -d '"' || true)
            distro="${distro_name} ${distro_ver}"
        fi
    fi

    if [ -z "$distro" ]; then
        distro=$(uname -s)
    fi

    os_desc="${distro} (${arch})"

    echo "- OS: ${os_desc}"
    echo "- Kernel: ${kernel_info}"
    echo "- Hostname: ${host_name}"
    echo "- Uptime: ${uptime_info}"
    echo "- Date: ${now_str}"
fi
