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
    echo "Error: Mac manifest dump requires macOS (current: $(uname -s))" >&2
    exit 1
fi

# Validate brew command
if ! command -v brew >/dev/null 2>&1; then
    echo "Error: 'brew' command not found." >&2
    exit 1
fi

TARGET_FILE="${REPO_DIR}/scripts/Brewfile"
mkdir -p "$(dirname "${TARGET_FILE}")"

echo "Dumping Mac Homebrew manifest to ${TARGET_FILE}..."
brew bundle dump --force --file="${TARGET_FILE}"
echo "Mac manifest dumped to ${TARGET_FILE}"
