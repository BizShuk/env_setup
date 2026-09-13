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

DRY_RUN=false
for arg in "$@"; do
    case "${arg}" in
        --dry-run|-n)
            DRY_RUN=true
            ;;
        --help|-h)
            echo "Usage: $(basename "$0") [--dry-run|-n]"
            echo "Install Antigravity extensions from bin/vscode/agy-ide_extension_list.txt"
            exit 0
            ;;
        *)
            echo "Error: unknown argument '${arg}'" >&2
            echo "Usage: $(basename "$0") [--dry-run|-n]" >&2
            exit 1
            ;;
    esac
done

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

MANIFEST_FILE="${REPO_DIR}/bin/vscode/agy-ide_extension_list.txt"
if [ ! -f "${MANIFEST_FILE}" ]; then
    echo "Error: manifest file not found: ${MANIFEST_FILE}" >&2
    exit 1
fi

extensions=()
while IFS= read -r line || [ -n "${line}" ]; do
    line="${line//$'\r'/}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    if [ -z "${line}" ] || [[ "${line}" == \#* ]]; then
        continue
    fi
    extensions+=("${line}")
done < "${MANIFEST_FILE}"

if [ "${#extensions[@]}" -eq 0 ]; then
    echo "Warning: no extensions found in ${MANIFEST_FILE}"
    exit 0
fi

if [ "${DRY_RUN}" = true ]; then
    echo "[dry-run] Found ${#extensions[@]} extensions to install from ${MANIFEST_FILE}:"
    if [ -n "${EXT_DIR}" ]; then
        echo "[dry-run] Antigravity extensions directory: ${EXT_DIR}"
    fi
    for ext in "${extensions[@]}"; do
        if [ -n "${EXT_DIR}" ]; then
            echo "  [dry-run] ${AGY_CMD} --extensions-dir ${EXT_DIR} --install-extension ${ext} --force"
        else
            echo "  [dry-run] ${AGY_CMD} --install-extension ${ext} --force"
        fi
    done
    exit 0
fi

if [ -n "${EXT_DIR}" ]; then
    echo "Antigravity extensions directory: ${EXT_DIR}"
fi

echo "Installing ${#extensions[@]} Antigravity extensions from ${MANIFEST_FILE}..."
success_count=0
failed_count=0
failed_extensions=()

for ext in "${extensions[@]}"; do
    echo "Installing Antigravity extension: ${ext}"
    if [ -n "${EXT_DIR}" ]; then
        CMD_ARGS=(--extensions-dir "${EXT_DIR}" --install-extension "${ext}" --force)
    else
        CMD_ARGS=(--install-extension "${ext}" --force)
    fi

    if "${AGY_CMD}" "${CMD_ARGS[@]}"; then
        success_count=$((success_count + 1))
    else
        echo "Error: failed to install Antigravity extension: ${ext}" >&2
        failed_count=$((failed_count + 1))
        failed_extensions+=("${ext}")
    fi
done

echo ""
echo "=== Installation Summary ==="
echo "Total: ${#extensions[@]}, Succeeded: ${success_count}, Failed: ${failed_count}"

if [ "${failed_count}" -gt 0 ]; then
    echo "Failed extensions:" >&2
    for ext in "${failed_extensions[@]}"; do
        echo "  - ${ext}" >&2
    done
    exit 1
fi
