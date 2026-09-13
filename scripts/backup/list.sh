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

for arg in "$@"; do
    case "${arg}" in
        --help|-h)
            echo "Usage: $(basename "$0")"
            echo "List tracked macOS defaults domains, backup status, and latest backup timestamp."
            exit 0
            ;;
        *)
            echo "Error: unknown argument '${arg}'" >&2
            echo "Usage: $(basename "$0")" >&2
            exit 1
            ;;
    esac
done

CONFIG_DIR="${CONFIG_DIR:-${HOME}/.config/env_setup}"
MANIFEST_FILE="${MANIFEST_FILE:-${CONFIG_DIR}/mac_backup_domains.json}"
if [ -z "${BACKUP_DIR:-}" ]; then
    if [ -d "${CONFIG_DIR}/backup" ] || [ ! -d "${CONFIG_DIR}/data/backup/mac" ]; then
        BACKUP_DIR="${CONFIG_DIR}/backup"
    else
        BACKUP_DIR="${CONFIG_DIR}/data/backup/mac"
    fi
fi
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

latest="-"
if [ -f "${META_FILE}" ]; then
    if command -v python3 >/dev/null 2>&1; then
        latest=$(python3 -c '
import json, sys, datetime
try:
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        meta = json.load(f)
    ts = meta.get("timestamp", "")
    dt = datetime.datetime.fromisoformat(ts)
    print(dt.strftime("%Y-%m-%d %H:%M:%S %z"))
except Exception:
    print("-")
' "${META_FILE}" 2>/dev/null | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/')
    elif command -v jq >/dev/null 2>&1; then
        latest=$(jq -r '.timestamp // "-"' "${META_FILE}" 2>/dev/null)
    fi
fi

if [ -z "${latest}" ] || [ "${latest}" = "-" ]; then
    if [ -d "${BACKUP_DIR}" ]; then
        newest_plist=$(find "${BACKUP_DIR}" -maxdepth 1 -name "*.plist" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -n 1 || true)
        if [ -n "${newest_plist}" ] && [ -f "${newest_plist}" ]; then
            latest=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S %z" "${newest_plist}" 2>/dev/null | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/' || echo "-")
        fi
    fi
fi

echo "manifest: ${MANIFEST_FILE}"
echo "backup:   ${BACKUP_DIR}"
echo "latest:   ${latest}"
echo ""

printf "%-8s %-8s %-10s %-52s %s\n" "BACKUP" "LIVE" "SIZE" "DOMAIN" "NOTE"

while IFS=$'\t' read -r domain note || [ -n "${domain}" ]; do
    [ -z "${domain}" ] && continue

    plist_file="${BACKUP_DIR}/${domain}.plist"
    backup_status="-"
    size_str="-"

    if [ -f "${plist_file}" ]; then
        backup_status="yes"
        # shellcheck disable=SC2012
        size_str=$(ls -lh "${plist_file}" 2>/dev/null | awk '{print $5}' || echo "-")
    fi

    live_status="-"
    if defaults read "${domain}" >/dev/null 2>&1; then
        live_status="yes"
    fi

    printf "%-8s %-8s %-10s %-52s %s\n" "${backup_status}" "${live_status}" "${size_str}" "${domain}" "${note}"
done < <(parse_domains "${MANIFEST_FILE}")
