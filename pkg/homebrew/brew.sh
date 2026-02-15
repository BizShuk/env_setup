#!/bin/bash

source "${HOME}"/settings.sh

homebrew_ver="4.1.11"
homebrew_ver="5.0.3"

pushd "${USER_LOCAL}" || exit

rm -rf homebrew
# mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
mkdir homebrew && curl -L https://github.com/Homebrew/brew/archive/refs/tags/${homebrew_ver}.tar.gz | tar xz --strip 1 -C homebrew

# git clone https://github.com/Homebrew/brew homebrew

echo -e "\n\n\n# Homwbrew" >>"${HOME}/.bash_plugin"

./homebrew/bin/brew shellenv >>"${HOME}/.bash_plugin"
echo export SSL_CERT_FILE="$(brew --prefix)/etc/ca-certificates/cert.pem" >> "${HOME}"/.bash_plugin
popd || exit

source "${HOME}/.bash_plugin"
brew postinstall ca-certificates
brew update --force
chmod -R go-w "$(brew --prefix)/share/zsh"




