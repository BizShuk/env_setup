#!/bin/bash
set -euo pipefail

# ============================================================================
# pnpm.sh — Install pinned pnpm and global packages
# ============================================================================
# Requires Node.js on PATH (or nvm at ${USER_LIB}/nvm) for global Node packages.
# ============================================================================

source "$(dirname "$0")/settings.sh"
# shellcheck source=./_lib_bash_plugin.sh
source "$(dirname "$0")/_lib_bash_plugin.sh"

PNPM_VER=${PNPM_VER:-12.4.1}
PNPM_HOME="${USER_LIB}/pnpm"
NVM_DIR="${USER_LIB}/nvm"

if [ -s "${NVM_DIR}/nvm.sh" ]; then
    export NVM_DIR
    # shellcheck source=/dev/null
    source "${NVM_DIR}/nvm.sh"
fi

if ! command -v node >/dev/null 2>&1; then
    echo "Node.js is required. Run ./scripts/nodejs_nvm.sh first." >&2
    exit 1
fi

PNPM_PLATFORM=""
case "${OS}" in
darwin) PNPM_PLATFORM="darwin" ;;
linux) PNPM_PLATFORM="linux" ;;
*)
    echo "Unsupported OS for pnpm binary: ${OS}" >&2
    exit 1
    ;;
esac

PNPM_ARCH=""
case "${CPU_ARCH}" in
arm64 | aarch64) PNPM_ARCH="arm64" ;;
x86_64 | amd64) PNPM_ARCH="x64" ;;
*)
    echo "Unsupported arch for pnpm binary: ${CPU_ARCH}" >&2
    exit 1
    ;;
esac

PNPM_ASSET="pnpm-${PNPM_PLATFORM}-${PNPM_ARCH}"
PNPM_URL="https://github.com/pnpm/pnpm/releases/download/v${PNPM_VER}/${PNPM_ASSET}.tar.gz"

CURRENT=""
if [ -x "${PNPM_HOME}/pnpm" ]; then
    CURRENT="$("${PNPM_HOME}/pnpm" --version 2>/dev/null || true)"
fi

if [ "${CURRENT}" != "${PNPM_VER}" ]; then
    echo "Installing pnpm ${PNPM_VER} (${PNPM_ASSET})..."
    PNPM_TMP="$(mktemp -d)"
    trap 'rm -rf "${PNPM_TMP}"' EXIT
    curl -fL --proto '=https' --tlsv1.2 "${PNPM_URL}" -o "${PNPM_TMP}/pnpm.tar.gz"
    mkdir -p "${PNPM_HOME}/bin"
    tar -xzf "${PNPM_TMP}/pnpm.tar.gz" -C "${PNPM_HOME}"
    chmod +x "${PNPM_HOME}/pnpm"
    rm -rf "${PNPM_TMP}"
    trap - EXIT
fi

ln -sf "${PNPM_HOME}/pnpm" "${USER_BIN}/pnpm"

update_bash_plugin_block "pnpm" \
    '/^# \[NodeJs:npm\]$/d' \
    '/^export PATH=.*\/npm.*\/bin/d' \
    '/^export PNPM_HOME=/d' \
    '/^export PATH=.*\/pnpm/d' \
    '/^alias npm=pnpm$/d' <<EOF
export PNPM_HOME="${PNPM_HOME}"
export PATH="\${PNPM_HOME}:\${PNPM_HOME}/bin:\${PATH}"
alias npm=pnpm
EOF

# shellcheck source=/dev/null
source "${BASH_PLUGIN}"

export PATH="${PNPM_HOME}:${PNPM_HOME}/bin:${PATH}"
"${PNPM_HOME}/pnpm" add -g pm2
