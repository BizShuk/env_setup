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
使用方式: probe.sh [選項]

探測實體儲存裝置與傳輸特性 (DEV, TRAN, MODEL, SIZE, MOUNTS)

選項:
      --bench           執行磁碟 I/O 評測 (調用 bench.sh)
  -d, --dir <DIR>       評測測試目錄 (搭配 --bench，預設: /tmp)
  -s, --size <MB>       循序測試樣本大小 (MiB，預設: 64)
      --seq-mib <MB>    同 --size
  -o, --ops <COUNT>     4K 隨機/同步操作次數 (預設: 50)
  -h, --help            顯示此說明訊息
EOF
}

do_bench=false
bench_dir=""
bench_size=""
bench_ops=""

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        --bench)
            do_bench=true
            shift
            ;;
        -d|--dir)
            if [ $# -lt 2 ]; then
                echo "錯誤: -d/--dir 需要指定目錄路徑" >&2
                exit 1
            fi
            bench_dir="$2"
            shift 2
            ;;
        -s|--size|--seq-mib)
            if [ $# -lt 2 ]; then
                echo "錯誤: $1 需要指定大小 (MB)" >&2
                exit 1
            fi
            bench_size="$2"
            bench_size="${bench_size%[bB]}"
            bench_size="${bench_size%[iI]}"
            bench_size="${bench_size%[mM]}"
            shift 2
            ;;
        -o|--ops)
            if [ $# -lt 2 ]; then
                echo "錯誤: $1 需要指定次數" >&2
                exit 1
            fi
            bench_ops="$2"
            shift 2
            ;;
        -*)
            echo "錯誤: 未知選項 $1" >&2
            show_help >&2
            exit 1
            ;;
        *)
            echo "錯誤: 未知引數 $1" >&2
            show_help >&2
            exit 1
            ;;
    esac
done

probe_darwin() {
    if ! command -v diskutil >/dev/null 2>&1; then
        echo "錯誤: 找不到 'diskutil' 命令" >&2
        return 1
    fi

    if command -v python3 >/dev/null 2>&1 && command -v plutil >/dev/null 2>&1; then
        diskutil list -plist 2>/dev/null | plutil -convert json -o - - 2>/dev/null | python3 -c '
import sys, json, subprocess

try:
    list_data = json.load(sys.stdin)
except Exception:
    sys.exit(1)

whole_disks = list_data.get("WholeDisks", [])
all_disks = list_data.get("AllDisksAndPartitions", [])

partition_owner = {}
for disk in all_disks:
    for part in disk.get("Partitions", []):
        p_id = part.get("DeviceIdentifier")
        if p_id:
            partition_owner[p_id] = disk.get("DeviceIdentifier")

mounts = {}
for disk in all_disks:
    d_id = disk.get("DeviceIdentifier")
    for part in disk.get("Partitions", []):
        mp = part.get("MountPoint")
        if mp:
            dev_id = part.get("DeviceIdentifier")
            mounts.setdefault(d_id, []).append(f"{dev_id}={mp}")

    physical_stores = disk.get("APFSPhysicalStores", [])
    if physical_stores:
        ps_id = physical_stores[0].get("DeviceIdentifier")
        owner = partition_owner.get(ps_id, d_id)
        for vol in disk.get("APFSVolumes", []):
            mp = vol.get("MountPoint")
            if mp:
                dev_id = vol.get("DeviceIdentifier")
                mounts.setdefault(owner, []).append(f"{dev_id}={mp}")

results = []
for name in whole_disks:
    cmd = ["diskutil", "info", "-plist", name]
    try:
        out = subprocess.run(cmd, capture_output=True, check=True).stdout
        info_json = subprocess.run(["plutil", "-convert", "json", "-o", "-", "-"], input=out, capture_output=True, check=True).stdout
        info = json.loads(info_json)
    except Exception:
        continue
    if info.get("VirtualOrPhysical") == "Virtual":
        continue
    dev = name
    tran = (info.get("BusProtocol") or "-").lower()
    model = info.get("MediaName") or "-"
    size = info.get("TotalSize") or 0
    if size >= 1024**4:
        size_str = f"{size / (1024**4):.1f}T"
    elif size >= 1024**3:
        size_str = f"{size / (1024**3):.1f}G"
    elif size >= 1024**2:
        size_str = f"{size / (1024**2):.1f}M"
    elif size > 0:
        size_str = f"{size}B"
    else:
        size_str = "-"
    m_list = ",".join(mounts.get(name, [])) or "-"
    results.append((dev, tran, model, size_str, m_list))

print("DEV\tTRAN\tMODEL\tSIZE\tMOUNTS")
for dev, tran, model, size_str, m_list in results:
    print(f"{dev}\t{tran}\t{model}\t{size_str}\t{m_list}")
' | column -t -s $'\t'
    else
        printf "%-8s %-14s %-22s %-10s %s\n" "DEV" "TRAN" "MODEL" "SIZE" "MOUNTS"
        local disks
        disks=$(diskutil list 2>/dev/null | awk '/^\/dev\/disk[0-9]+ \((internal|external), physical\)/ { sub(/^\/dev\//, "", $1); print $1 }')
        for d in ${disks}; do
            local info
            info=$(diskutil info "${d}" 2>/dev/null)
            local proto
            proto=$(echo "${info}" | awk -F': *' '/Protocol:/ {print tolower($2); exit}')
            local model
            model=$(echo "${info}" | awk -F': *' '/Device \/ Media Name:/ {print $2; exit}')
            local size
            size=$(echo "${info}" | awk -F': *' '/Disk Size:/ {print $2; exit}' | sed -E 's/ \([0-9]+ Bytes\).*//')
            local mounts
            mounts=$(mount | awk -v dev="/dev/${d}" '$1 ~ dev {print $1"="$3}' | tr '\n' ',' | sed 's/,$//')
            if [ -z "${mounts}" ]; then
                mounts="-"
            fi
            printf "%-8s %-14s %-22s %-10s %s\n" "${d}" "${proto:--}" "${model:--}" "${size:--}" "${mounts}"
        done
    fi
}

probe_linux() {
    if ! command -v lsblk >/dev/null 2>&1; then
        echo "錯誤: 找不到 'lsblk' 命令" >&2
        return 1
    fi

    if lsblk -d -o NAME,TRAN,MODEL,SIZE,ROTA,TYPE,MOUNTPOINTS >/dev/null 2>&1; then
        lsblk -d -o NAME,TRAN,MODEL,SIZE,ROTA,TYPE,MOUNTPOINTS
    elif lsblk -d -o NAME,TRAN,MODEL,SIZE,ROTA,TYPE,MOUNTPOINT >/dev/null 2>&1; then
        lsblk -d -o NAME,TRAN,MODEL,SIZE,ROTA,TYPE,MOUNTPOINT
    else
        lsblk -d -o NAME,MODEL,SIZE,ROTA,TYPE
    fi
}

case "${OS}" in
    darwin*)
        probe_darwin
        ;;
    linux*)
        probe_linux
        ;;
    *)
        echo "錯誤: 不支援的作業系統: ${OS}" >&2
        exit 1
        ;;
esac

if [ "${do_bench}" = true ]; then
    echo ""
    bench_cmd=("${SCRIPT_DIR}/bench.sh")
    if [ -n "${bench_dir}" ]; then
        bench_cmd+=("-d" "${bench_dir}")
    fi
    if [ -n "${bench_size}" ]; then
        bench_cmd+=("-s" "${bench_size}")
    fi
    if [ -n "${bench_ops}" ]; then
        bench_cmd+=("-o" "${bench_ops}")
    fi
    "${bench_cmd[@]}"
fi
