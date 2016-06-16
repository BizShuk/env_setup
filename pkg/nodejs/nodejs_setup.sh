#!/bin/bash
# [NVM github](https://github.com/creationix/nvm)

node_version="v4.4.5"  #  v4.4.5 LTS

rm -rf ~/.nvm
git clone https://github.com/creationix/nvm.git ~/.nvm && cd ~/.nvm && git checkout `git describe --abbrev=0 --tags`

. ~/.nvm/nvm.sh

echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bash_plugin
echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> ~/.bash_plugin


nvm install $node_version
nvm use $node_version
nvm alias default $node_version