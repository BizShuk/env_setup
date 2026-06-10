#!/bin/bash
set -euo pipefail
# [NVM github](https://github.com/nvm-sh/nvm)

source "$(dirname "$0")/settings.sh"

NODE_VER=${NODE_VER:-v24.11.1}
NVM_DIR=${USER_LIB}/nvm

rm -rf "${NVM_DIR}"
mkdir "${NVM_DIR}"

git clone https://github.com/nvm-sh/nvm.git "${NVM_DIR}"

cd "${NVM_DIR}" || exit 1
git checkout "$(git describe --abbrev=0 --tags)"

# shellcheck source=/dev/null
source "${NVM_DIR}/nvm.sh"

# NODE installation """

nvm install --lts
nvm install "$NODE_VER"
nvm use "$NODE_VER"
nvm alias default "$NODE_VER"

cat <<EOF >>~/.bash_plugin
# [NodeJs:nvm]
export NVM_DIR=${NVM_DIR}
source ${NVM_DIR}/nvm.sh
export PATH=\${NVM_DIR}/versions/node/${NODE_VER}/bin:\${PATH}

EOF

nvm use --delete-prefix "${NODE_VER}" --silent



# shellcheck source=/dev/null
source ${HOME}/.bash_plugin

NPM_PREFIX=$(npm config get prefix)
cat <<EOF >>~/.bash_plugin
# [NodeJs:npm]
export PATH=${NPM_PREFIX}/bin:\$PATH

EOF

# shellcheck source=/dev/null
source ${HOME}/.bash_plugin


npm install -g pm2