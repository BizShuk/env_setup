#!/bin/bash

# [Notice]
# .bashrc will not execute , but .bash_profile will
# need to restart terminal or source .bash_profile

~/project/env_setup/pkg/mac/brew.sh
source ~/.profile

# [Basic]
brew install git curl wget jq

echo -e "\n# [curl]" >>~/.bash_plugin
echo "export PATH=$(brew --prefix curl)/bin:\${PATH}" >>~/.bash_plugin
