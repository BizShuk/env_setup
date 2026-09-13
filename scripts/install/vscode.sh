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
            echo "Install VS Code extensions from bin/vscode/vscode_extension_list.txt"
            exit 0
            ;;
        *)
            echo "Error: unknown argument '${arg}'" >&2
            echo "Usage: $(basename "$0") [--dry-run|-n]" >&2
            exit 1
            ;;
    esac
done

# Validate code command
if ! command -v code >/dev/null 2>&1; then
    echo "Error: 'code' command not found." >&2
    exit 1
fi

MANIFEST_FILE="${REPO_DIR}/bin/vscode/vscode_extension_list.txt"
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
    for ext in "${extensions[@]}"; do
        echo "  [dry-run] code --install-extension ${ext} --force"
    done
    exit 0
fi

echo "Installing ${#extensions[@]} VS Code extensions from ${MANIFEST_FILE}..."
success_count=0
failed_count=0
failed_extensions=()

for ext in "${extensions[@]}"; do
    echo "Installing VS Code extension: ${ext}"
    if code --install-extension "${ext}" --force; then
        success_count=$((success_count + 1))
    else
        echo "Error: failed to install VS Code extension: ${ext}" >&2
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
