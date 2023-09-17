#!/bin/bash

source settings.sh

homebrew_ver="4.1.11"

pushd ${USER_BIN}

rm -rf homebrew
# mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
mkdir homebrew && curl -L https://github.com/Homebrew/brew/archive/refs/tags/${homebrew_ver}.tar.gz | tar xz --strip 1 -C homebrew

# git clone https://github.com/Homebrew/brew homebrew

echo -e "\n\n\n# Homwbrew" >>~/.bash_plugin

echo "$(./homebrew/bin/brew shellenv)" >>~/.bash_plugin

source ~/.bash_plugin
brew update --force
chmod -R go-w "$(brew --prefix)/share/zsh"

popd
