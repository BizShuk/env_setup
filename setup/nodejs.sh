#!/bin/bash
# [NVM github](https://github.com/creationix/nvm)

source "${HOME}"/settings.sh

NODE_VER=${NODE_VER:-v24.11.1}
NVM_DIR=${USER_LIB}/nvm

rm -rf "${NVM_DIR}"
mkdir "${NVM_DIR}"

git clone https://github.com/creationix/nvm.git "${NVM_DIR}"

cd "${NVM_DIR}" && git checkout $(git describe --abbrev=0 --tags)

. "${NVM_DIR}/nvm.sh"

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

#  NPM
echo run this if npm is not there: curl -L http://npmjs.org/install.sh | sh
echo "# [NodeJs:npm]"
echo "export PATH=$(npm config get prefix)/bin:\$PATH" >>~/.bash_plugin
