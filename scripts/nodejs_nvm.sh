#!/bin/bash
set -euo pipefail

# ============================================================================
# nodejs_nvm.sh — Install nvm and a pinned Node.js runtime
# ============================================================================

source "$(dirname "$0")/settings.sh"
# shellcheck source=./_lib_bash_plugin.sh
source "$(dirname "$0")/_lib_bash_plugin.sh"

NODE_VER=${NODE_VER:-v24.11.1}
NVM_DIR=${USER_LIB}/nvm

rm -rf "${NVM_DIR}"
mkdir "${NVM_DIR}"

git clone https://github.com/nvm-sh/nvm.git "${NVM_DIR}"

cd "${NVM_DIR}" || exit 1
git checkout "$(git describe --abbrev=0 --tags)"

# shellcheck source=/dev/null
source "${NVM_DIR}/nvm.sh"

nvm install --lts
nvm install "$NODE_VER"
nvm use "$NODE_VER"
nvm alias default "$NODE_VER"
nvm use --delete-prefix "${NODE_VER}" --silent

# pnpm is this repo's only package manager. Every Node.js tarball ships npm,
# npx and corepack; strip them from each installed version so no command,
# script or editor can silently fall back to npm.
for node_root in "${NVM_DIR}"/versions/node/*; do
    [ -d "${node_root}" ] || continue
    rm -rf \
        "${node_root}/lib/node_modules/npm" \
        "${node_root}/lib/node_modules/corepack" \
        "${node_root}/bin/npm" \
        "${node_root}/bin/npx" \
        "${node_root}/bin/corepack"
done

update_bash_plugin_block "nodejs" \
    '/^# \[NodeJs:nvm\]$/d' \
    '/^export NVM_DIR=/d' \
    '/^source .*\/nvm\.sh$/d' \
    '/^\[ -s ".*\/nvm\.sh" \] && /d' \
    '/^export PATH=.*\/versions\/node\/.*\/bin/d' <<EOF
export NVM_DIR="${NVM_DIR}"
[ -s "${NVM_DIR}/nvm.sh" ] && source "${NVM_DIR}/nvm.sh"
export PATH="${NVM_DIR}/versions/node/${NODE_VER}/bin:\${PATH}"
EOF
