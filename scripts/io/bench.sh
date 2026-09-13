#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi

show_help() {
    cat << 'EOF'
使用方式: bench.sh [選項]

評測磁碟 I/O 效能 (循序寫入、4K 同步寫入 IOPS/延遲、循序讀取、4K 隨機讀取)

選項:
  -d, --dir <DIR>       測試目標目錄 (預設: /tmp)
  -s, --size <MB>       循序測試樣本大小 (MiB，預設: 64)
      --seq-mib <MB>    同 --size
  -o, --ops <COUNT>     4K 隨機/同步操作次數 (預設: 50)
  -h, --help            顯示此說明訊息
EOF
}

target_dir="${TMPDIR:-/tmp}"
size_mb=64
ops=50

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dir)
            if [ $# -lt 2 ]; then
                echo "錯誤: -d/--dir 需要指定目錄路徑" >&2
                exit 1
            fi
            target_dir="$2"
            shift 2
            ;;
        -s|--size|--seq-mib)
            if [ $# -lt 2 ]; then
                echo "錯誤: $1 需要指定大小 (MB)" >&2
                exit 1
            fi
            size_mb="$2"
            size_mb="${size_mb%[bB]}"
            size_mb="${size_mb%[iI]}"
            size_mb="${size_mb%[mM]}"
            shift 2
            ;;
        -o|--ops)
            if [ $# -lt 2 ]; then
                echo "錯誤: $1 需要指定次數" >&2
                exit 1
            fi
            ops="$2"
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

if [ ! -d "${target_dir}" ]; then
    echo "錯誤: 目錄不存在: ${target_dir}" >&2
    exit 1
fi

if [ ! -w "${target_dir}" ]; then
    echo "錯誤: 目錄無寫入權限: ${target_dir}" >&2
    exit 1
fi

if ! [[ "${size_mb}" =~ ^[0-9]+$ ]] || [ "${size_mb}" -le 0 ]; then
    echo "錯誤: 大小必須為大於 0 的整數: ${size_mb}" >&2
    exit 1
fi

if ! [[ "${ops}" =~ ^[0-9]+$ ]] || [ "${ops}" -le 0 ]; then
    echo "錯誤: 次數必須為大於 0 的整數: ${ops}" >&2
    exit 1
fi

TEST_FILE="${target_dir}/.io-bench-$$.tmp"
trap 'rm -f "${TEST_FILE:-}"' EXIT INT TERM

get_time() {
    local raw=""
    if raw=$(date +%s%N 2>/dev/null) && [[ "${raw}" =~ ^[0-9]{15,22}$ ]]; then
        local sec="${raw:0:${#raw}-9}"
        local nano="${raw:${#raw}-9}"
        echo "${sec}.${nano}"
    elif command -v python3 >/dev/null 2>&1; then
        python3 -c 'import time; print(f"{time.time():.6f}")'
    elif command -v perl >/dev/null 2>&1; then
        perl -MTime::HiRes=time -e 'printf "%.6f\n", time'
    else
        date +%s
    fi
}

calc_elapsed() {
    local start="$1"
    local end="$2"
    awk -v s="${start}" -v e="${end}" 'BEGIN {
        el = e - s
        if (el <= 0) el = 0.000001
        printf "%.6f", el
    }'
}

calc_throughput() {
    local mib="$1"
    local elapsed="$2"
    awk -v s="${mib}" -v e="${elapsed}" 'BEGIN {
        if (e <= 0) e = 0.000001
        rate = s / e
        printf "%.0f", rate
    }'
}

calc_iops() {
    local count="$1"
    local elapsed="$2"
    awk -v o="${count}" -v e="${elapsed}" 'BEGIN {
        if (e <= 0) e = 0.000001
        printf "%.0f", o / e
    }'
}

calc_latency() {
    local count="$1"
    local elapsed="$2"
    awk -v o="${count}" -v e="${elapsed}" 'BEGIN {
        if (o <= 0) o = 1
        printf "%.1f", (e * 1000.0) / o
    }'
}

echo "bench in ${target_dir}"

# 1. Sequential Write
t0=$(get_time)
dd if=/dev/zero of="${TEST_FILE}" bs=1048576 count="${size_mb}" 2>/dev/null
sync
t1=$(get_time)
el_seq_wr=$(calc_elapsed "${t0}" "${t1}")
tp_seq_wr=$(calc_throughput "${size_mb}" "${el_seq_wr}")
printf "%-11s %-10s (%d MiB, 1 MiB blocks, direct + sync)\n" "seq write" "${tp_seq_wr} MB/s" "${size_mb}"

# 2. 4K Sync Write
t0=$(get_time)
for ((i = 0; i < ops; i++)); do
    dd if=/dev/zero of="${TEST_FILE}" bs=4096 count=1 seek="${i}" conv=notrunc 2>/dev/null
    sync
done
t1=$(get_time)
el_sync_wr=$(calc_elapsed "${t0}" "${t1}")
iops_sync_wr=$(calc_iops "${ops}" "${el_sync_wr}")
lat_sync_wr=$(calc_latency "${ops}" "${el_sync_wr}")
printf "%-11s %-10s (%s ms/op, direct + sync per write)\n" "4k sync wr" "${iops_sync_wr} IOPS" "${lat_sync_wr}"

# 3. Sequential Read
t0=$(get_time)
dd if="${TEST_FILE}" of=/dev/null bs=1048576 count="${size_mb}" 2>/dev/null
t1=$(get_time)
el_seq_rd=$(calc_elapsed "${t0}" "${t1}")
tp_seq_rd=$(calc_throughput "${size_mb}" "${el_seq_rd}")
printf "%-11s %-10s (%d MiB, 1 MiB blocks)\n" "seq read" "${tp_seq_rd} MB/s" "${size_mb}"

# 4. 4K Random Read
max_blocks=$(( size_mb * 256 ))
if [ "${max_blocks}" -le 0 ]; then
    max_blocks=1
fi
t0=$(get_time)
for ((i = 0; i < ops; i++)); do
    offset=$(( (RANDOM * 32768 + RANDOM) % max_blocks ))
    dd if="${TEST_FILE}" of=/dev/null bs=4096 count=1 skip="${offset}" 2>/dev/null
done
t1=$(get_time)
el_rand_rd=$(calc_elapsed "${t0}" "${t1}")
iops_rand_rd=$(calc_iops "${ops}" "${el_rand_rd}")
lat_rand_rd=$(calc_latency "${ops}" "${el_rand_rd}")
printf "%-11s %-10s (%s ms/op, direct)\n" "4k rand rd" "${iops_rand_rd} IOPS" "${lat_rand_rd}"
