#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Validate operating system
if [ "$(uname -s)" != "Darwin" ]; then
    echo "Error: macOS defaults backup requires Darwin (macOS). Current OS: $(uname -s)" >&2
    exit 1
fi

# Validate required tools
for tool in defaults plutil; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo "Error: required tool '${tool}' not found." >&2
        exit 1
    fi
done

DRY_RUN=false
for arg in "$@"; do
    case "${arg}" in
        --dry-run|-n)
            DRY_RUN=true
            ;;
        --help|-h)
            echo "Usage: $(basename "$0") [--dry-run|-n]"
            echo "Backup macOS defaults domains defined in mac_backup_domains.json."
            exit 0
            ;;
        *)
            echo "Error: unknown argument '${arg}'" >&2
            echo "Usage: $(basename "$0") [--dry-run|-n]" >&2
            exit 1
            ;;
    esac
done

CONFIG_DIR="${CONFIG_DIR:-${HOME}/.config/env_setup}"
MANIFEST_FILE="${MANIFEST_FILE:-${CONFIG_DIR}/mac_backup_domains.json}"
BACKUP_DIR="${BACKUP_DIR:-${CONFIG_DIR}/backup}"
META_FILE="${BACKUP_DIR}/backup.meta.json"

if [ ! -f "${MANIFEST_FILE}" ]; then
    echo "網域清單不存在，自動初始化: ${MANIFEST_FILE}"
    "${SCRIPT_DIR}/init.sh"
fi

parse_domains() {
    local json_file="$1"
    if command -v python3 >/dev/null 2>&1; then
        python3 -c '
import json, sys
try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        data = json.load(f)
    for item in data:
        d = item.get("domain", "").strip()
        if d:
            n = item.get("note", "").strip()
            print(f"{d}\t{n}")
except Exception:
    sys.exit(1)
' "${json_file}"
    elif command -v jq >/dev/null 2>&1; then
        jq -r '.[] | "\(.domain)\t\(.note // "")"' "${json_file}"
    else
        sed -n 's/.*"domain"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1\t/p' "${json_file}"
    fi
}

write_meta() {
    local meta_file="$1"
    local host
    host="$(hostname)"
    if command -v python3 >/dev/null 2>&1; then
        python3 -c '
import json, sys, datetime
meta_file = sys.argv[1]
host = sys.argv[2]
domains = sys.argv[3:]
ts = datetime.datetime.now().astimezone().replace(microsecond=0).isoformat()
data = {
    "timestamp": ts,
    "host": host,
    "domains": domains
}
with open(meta_file, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
' "${meta_file}" "${host}" "${saved_domains[@]}"
    else
        local ts
        ts="$(date +"%Y-%m-%dT%H:%M:%S%z" | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/')"
        local items=""
        for d in "${saved_domains[@]}"; do
            if [ -n "${items}" ]; then items="${items}, "; fi
            items="${items}\"${d}\""
        done
        cat <<EOF > "${meta_file}"
{
  "timestamp": "${ts}",
  "host": "${host}",
  "domains": [ ${items} ]
}
EOF
    fi
}

mkdir -p "${BACKUP_DIR}"

echo "備份 macOS 設定 -> ${BACKUP_DIR}"
echo ""

saved_domains=()
skipped_count=0
failed_count=0

while IFS=$'\t' read -r domain note || [ -n "${domain}" ]; do
    [ -z "${domain}" ] && continue

    if ! defaults read "${domain}" >/dev/null 2>&1; then
        printf "  skip  %-52s (本機無此網域)\n" "${domain}"
        skipped_count=$((skipped_count + 1))
        continue
    fi

    dest_plist="${BACKUP_DIR}/${domain}.plist"

    if [ "${DRY_RUN}" = true ]; then
        printf "  [dry-run] %-44s -> %s\n" "${domain}" "${dest_plist}"
        saved_domains+=("${domain}")
        continue
    fi

    if defaults export "${domain}" "${dest_plist}" 2>/dev/null && plutil -convert xml1 "${dest_plist}" 2>/dev/null; then
        printf "  ok    %-52s %s\n" "${domain}" "${note}"
        saved_domains+=("${domain}")
    else
        printf "  fail  %-52s 匯出或格式轉換失敗\n" "${domain}"
        failed_count=$((failed_count + 1))
    fi
done < <(parse_domains "${MANIFEST_FILE}")

if [ "${DRY_RUN}" = false ] && [ "${#saved_domains[@]}" -gt 0 ]; then
    write_meta "${META_FILE}"
fi

echo ""
echo "完成: ${#saved_domains[@]} 個網域已備份。"
if [ "${failed_count}" -gt 0 ]; then
    echo "失敗: ${failed_count} 個網域備份失敗。" >&2
    exit 1
fi
