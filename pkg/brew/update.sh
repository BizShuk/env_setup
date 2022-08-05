#!/bin/bash

git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask fetch --unshallow
git -C /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core fetch --unshallow
brew update && brew upgrade
#sudo xcode-select --install
brew install rbenv/tap/openssl@1.0
ln -sfn /usr/local/Cellar/openssl@1.0/1.0.2t /usr/local/opt/openssl
