#!/bin/bash

# Link the repo's AppleScript sources into ~/lib so LaunchAgents and Karabiner
# can reference a stable path. Idempotent: safe to re-run.

set -euo pipefail

# shellcheck source=../../bin/bash/settings.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../bin/bash/settings.sh"

if [ "${OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}" != "darwin" ]; then
    echo "Notice: pkg/mac/setup.sh requires macOS. Skipping."
    exit 0
fi

mkdir -p "${HOME}/lib"
ln -sfn "${REPO_PKG}/mac/applescript" "${HOME}/lib/applescript"

echo "Linked ${REPO_PKG}/mac/applescript -> ${HOME}/lib/applescript"
