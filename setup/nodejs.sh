#!/bin/bash
# [NVM github](https://github.com/creationix/nvm)

node_version="5.0.0"

rm -rf ~/.nvm
git clone https://github.com/creationix/nvm.git ~/.nvm && cd ~/.nvm && git checkout `git describe --abbrev=0 --tags`

. ~/.nvm/nvm.sh

echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bash_plugin
echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> ~/.bash_plugin


nvm install v$node_version
nvm use v$node_version
nvm alias default $node_version
