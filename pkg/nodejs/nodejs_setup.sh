#!/bin/bash
# [NVM github](https://github.com/creationix/nvm)

source settings.sh

NODE_VER=${NODE_VER:-v18.7.0}
NVM_DIR=${USER_LIB}/nvm

rm -rf ${NVM_DIR}
mkdir ${NVM_DIR}

git clone https://github.com/creationix/nvm.git ${NVM_DIR}

cd ${NVM_DIR} && git checkout $(git describe --abbrev=0 --tags)

. $NVM_DIR/nvm.sh

# NODE installation """

nvm install --lts
nvm install $NODE_VER
nvm use $NODE_VER
nvm alias default $NODE_VER

cat <<EOF >>~/.bash_plugin

# [NodeJs:nvm]
export NVM_DIR=${NVM_DIR}
source ${NVM_DIR}/nvm.sh
export PATH=\${NVM_DIR}/versions/node/${NODE_VER}/bin:\${PATH}
EOF

curl http://npmjs.org/install.sh | sh
