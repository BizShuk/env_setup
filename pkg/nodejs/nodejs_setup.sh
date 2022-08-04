#!/bin/bash
# [NVM github](https://github.com/creationix/nvm)

NODE_VER=${NODE_VER:-v18.7.0}
NVM_DIR=~/.nvm


### NVM installation """
[ ! -d $NVM_DIR ] && git clone https://github.com/creationix/nvm.git ~/.nvm && cd ~/.nvm && git checkout `git describe --abbrev=0 --tags`

. $NVM_DIR/nvm.sh

### NODE installation """
nvm install --lts
nvm install $NODE_VER
nvm use $NODE_VER
nvm alias default $NODE_VER


### Add NODE to PATH
cat <<EOF >> ~/.bash_plugin
# Node
export NVM_DIR=~/.nvm
export PATH=\$NVM_DIR/versions/node/$NODE_VER/bin:\$PATH
EOF