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

# Validate code command
if ! command -v code >/dev/null 2>&1; then
    echo "Error: 'code' command not found." >&2
    exit 1
fi

TARGET_FILE="${REPO_DIR}/bin/vscode/vscode_extension_list.txt"
mkdir -p "$(dirname "${TARGET_FILE}")"

TEMP_FILE="$(mktemp "${TARGET_FILE}.tmp.XXXXXX")"
ERR_FILE="$(mktemp "${TARGET_FILE}.err.XXXXXX")"
trap 'rm -f "${TEMP_FILE}" "${ERR_FILE}"' EXIT

if ! code --list-extensions 2>"${ERR_FILE}" \
    | tr -d '\r' \
    | { grep -v '^[[:space:]]*$' || true; } \
    | sort -u > "${TEMP_FILE}"; then
    cat "${ERR_FILE}" >&2
    echo "Error: failed to list VS Code extensions." >&2
    exit 1
fi

mv "${TEMP_FILE}" "${TARGET_FILE}"
rm -f "${ERR_FILE}"
trap - EXIT

COUNT=$(grep -c '[^[:space:]]' "${TARGET_FILE}" || true)
echo "${COUNT} extensions dumped to ${TARGET_FILE}"
