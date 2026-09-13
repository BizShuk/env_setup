#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Unset VSCODE_IPC_HOOK_CLI to avoid forwarding to remote window in integrated terminal
unset VSCODE_IPC_HOOK_CLI

# Check command: support both 'antigravity' and 'agy-ide'
if command -v antigravity >/dev/null 2>&1; then
    AGY_CMD="antigravity"
elif command -v agy-ide >/dev/null 2>&1; then
    AGY_CMD="agy-ide"
else
    echo "Error: 'antigravity' (or 'agy-ide') command not found." >&2
    exit 1
fi

# Resolve extensions directory
EXT_DIR=""
if [ -n "${AGY_EXTENSIONS_DIR:-}" ]; then
    EXT_DIR="${AGY_EXTENSIONS_DIR}"
elif [ -d "${HOME}/.antigravity-ide-server/extensions" ] && [ ! -d "${HOME}/.antigravity-ide/User" ]; then
    EXT_DIR="${HOME}/.antigravity-ide-server/extensions"
fi

if [ -n "${EXT_DIR}" ]; then
    CMD_ARGS=(--extensions-dir "${EXT_DIR}" --list-extensions)
else
    CMD_ARGS=(--list-extensions)
fi

TARGET_FILE="${REPO_DIR}/bin/vscode/agy-ide_extension_list.txt"
mkdir -p "$(dirname "${TARGET_FILE}")"

TEMP_FILE="$(mktemp "${TARGET_FILE}.tmp.XXXXXX")"
ERR_FILE="$(mktemp "${TARGET_FILE}.err.XXXXXX")"
trap 'rm -f "${TEMP_FILE}" "${ERR_FILE}"' EXIT

if ! "${AGY_CMD}" "${CMD_ARGS[@]}" 2>"${ERR_FILE}" \
    | tr -d '\r' \
    | { grep -v '^[[:space:]]*$' || true; } \
    | sort -u > "${TEMP_FILE}"; then
    cat "${ERR_FILE}" >&2
    echo "Error: failed to list Antigravity extensions." >&2
    exit 1
fi

mv "${TEMP_FILE}" "${TARGET_FILE}"
rm -f "${ERR_FILE}"
trap - EXIT

COUNT=$(grep -c '[^[:space:]]' "${TARGET_FILE}" || true)
echo "${COUNT} extensions dumped to ${TARGET_FILE}"
