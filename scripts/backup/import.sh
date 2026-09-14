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
    echo "Notice: macOS defaults backup requires Darwin (macOS). Current OS: $(uname -s). Skipping."
    exit 0
fi

# Validate required tools
for tool in defaults plutil diff; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo "Error: required tool '${tool}' not found." >&2
        exit 1
    fi
done

APPLY=false
YES_ALL=false
NO_DIFF=false
TARGET_DOMAIN=""

while [ $# -gt 0 ]; do
    case "$1" in
        --apply)
            APPLY=true
            shift
            ;;
        --yes|-y)
            YES_ALL=true
            shift
            ;;
        --no-diff)
            NO_DIFF=true
            shift
            ;;
        --diff)
            # Default preview mode
            shift
            ;;
        --domain)
            shift
            if [ $# -gt 0 ]; then
                TARGET_DOMAIN="$1"
                shift
            else
                echo "Error: --domain requires a domain name argument" >&2
                exit 1
            fi
            ;;
        --help|-h)
            echo "Usage: $(basename "$0") [--apply] [--yes|-y] [--no-diff] [--domain <domain>]"
            echo ""
            echo "Restore macOS defaults domains from backup plists."
            echo "SAFE BY DEFAULT: Defaults to Preview/Diff mode without modifying system defaults."
            echo ""
            echo "Options:"
            echo "  --apply            Actually apply/import settings (prompts [y/N] unless --yes)"
            echo "  --yes, -y          Skip interactive confirmation when --apply is set"
            echo "  --no-diff          Do not show line-by-line unified diff"
            echo "  --domain <domain>  Only inspect or restore the specified domain"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
        *)
            echo "Error: unknown argument '$1'" >&2
            echo "Usage: $(basename "$0") [--apply] [--yes|-y] [--no-diff] [--domain <domain>]" >&2
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

if [ ! -d "${BACKUP_DIR}" ]; then
    echo "Error: backup 目錄不存在，請先執行 scripts/backup/backup.sh: ${BACKUP_DIR}" >&2
    exit 1
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

confirm_prompt() {
    local domain="$1"
    local answer=""
    printf "  覆寫 %s? [y/N] " "${domain}"
    if read -r answer; then
        :
    else
        answer=""
    fi
    case "${answer}" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

TMP_DIFF_DIR=$(mktemp -d -t "macbackup-diff.XXXXXX")
trap 'rm -rf "${TMP_DIFF_DIR}"' EXIT

# Header output
if [ "${APPLY}" = false ]; then
    echo "============================================================"
    echo "  [Preview Mode] 匯入預覽 (Safe by Default)"
    echo "  未帶 --apply 參數，僅顯示差異，不會修改系統設定。"
    echo "============================================================"
else
    echo "============================================================"
    echo "  [Apply Mode] 匯入 (override) macOS 設定 <- ${BACKUP_DIR}"
    if [ "${YES_ALL}" = true ]; then
        echo "  模式: -y / --yes 全部同意，不逐一詢問"
    fi
    echo "============================================================"
fi
echo ""

diff_count=0
same_count=0
applied_count=0
skipped_count=0
failed_count=0

# Collect domain list
domain_entries=()
if [ -n "${TARGET_DOMAIN}" ]; then
    domain_entries+=("${TARGET_DOMAIN}"$'\t')
elif [ -f "${MANIFEST_FILE}" ]; then
    while IFS= read -r line || [ -n "${line}" ]; do
        [ -n "${line}" ] && domain_entries+=("${line}")
    done < <(parse_domains "${MANIFEST_FILE}")
else
    for plist in "${BACKUP_DIR}"/*.plist; do
        [ -f "${plist}" ] || continue
        dom="$(basename "${plist}" .plist)"
        domain_entries+=("${dom}"$'\t')
    done
fi

for entry in "${domain_entries[@]}"; do
    domain="${entry%%	*}"
    note="${entry#*	}"
    [ -z "${domain}" ] && continue

    backup_plist="${BACKUP_DIR}/${domain}.plist"
    if [ ! -f "${backup_plist}" ]; then
        continue
    fi

    echo "──────── ${domain} ────────"
    if [ -n "${note}" ]; then
        echo "  ${note}"
    fi

    cur_file="${TMP_DIFF_DIR}/current_${domain}.xml"
    bak_file="${TMP_DIFF_DIR}/backup_${domain}.xml"
    raw_file="${TMP_DIFF_DIR}/raw_${domain}.plist"

    # Normalize backup file to xml1
    plutil -convert xml1 -o "${bak_file}" "${backup_plist}" 2>/dev/null || cp "${backup_plist}" "${bak_file}"

    live_exists=false
    if defaults read "${domain}" >/dev/null 2>&1; then
        live_exists=true
    fi

    changed=false
    summary=""

    if [ "${live_exists}" = false ]; then
        changed=true
        summary="本機尚無此網域 → 將以 backup 建立。"
        touch "${cur_file}"
    else
        # Export live domain
        if defaults export "${domain}" "${raw_file}" 2>/dev/null; then
            plutil -convert xml1 -o "${cur_file}" "${raw_file}" 2>/dev/null || cp "${raw_file}" "${cur_file}"
        else
            touch "${cur_file}"
        fi

        if cmp -s "${cur_file}" "${bak_file}"; then
            changed=false
            summary="current == backup"
        else
            changed=true
            summary="current ≠ backup → 將以 backup 覆寫本機現值。"
        fi
    fi

    echo "  ${summary}"

    if [ "${changed}" = false ]; then
        echo "  → 內容相同，略過。"
        echo ""
        same_count=$((same_count + 1))
        skipped_count=$((skipped_count + 1))
        continue
    fi

    diff_count=$((diff_count + 1))

    # Show diff if enabled
    if [ "${NO_DIFF}" = false ] && { [ "${APPLY}" = false ] || [ "${YES_ALL}" = false ]; }; then
        diff_out=$(diff -u --label "current(本機現值)" "${cur_file}" --label "backup(將覆寫成)" "${bak_file}" 2>/dev/null || true)
        if [ -n "${diff_out}" ]; then
            printf '%s\n' "${diff_out}" | sed 's/^/  │ /'
        fi
    fi

    if [ "${APPLY}" = false ]; then
        echo ""
        continue
    fi

    # Apply mode confirmation
    if [ "${YES_ALL}" = false ]; then
        if ! confirm_prompt "${domain}"; then
            echo "  → 略過。"
            echo ""
            skipped_count=$((skipped_count + 1))
            continue
        fi
    fi

    if defaults import "${domain}" "${backup_plist}" 2>/dev/null; then
        printf "  ✓ 已覆寫 %s\n\n" "${domain}"
        applied_count=$((applied_count + 1))
    else
        printf "  ✗ 覆寫失敗: %s\n\n" "${domain}" >&2
        failed_count=$((failed_count + 1))
    fi
done

echo "────────────────────────────────────────────────────────────"
if [ "${APPLY}" = false ]; then
    echo "預覽結束: 發現 ${diff_count} 個網域有差異，${same_count} 個網域內容相同。"
    if [ "${diff_count}" -gt 0 ]; then
        echo ""
        echo "提示: 若要執行匯入，請加上 --apply 參數:"
        echo "  $0 --apply"
    fi
else
    echo "完成: 覆寫 ${applied_count} 個，略過 ${skipped_count} 個。"
    if [ "${applied_count}" -gt 0 ]; then
        echo "提示: 部分設定需登出 / 重啟對應 App (如 Dock, Finder) 才會生效。"
    fi
    if [ "${failed_count}" -gt 0 ]; then
        echo "失敗: ${failed_count} 個網域覆寫失敗。" >&2
        exit 1
    fi
fi
