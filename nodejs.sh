#!/bin/bash



# for mac
#brew install nvm



# install nvm
curl https://raw.githubusercontent.com/creationix/nvm/v0.23.3/install.sh | bash

echo 'source $(brew --prefix nvm)/nvm.sh' >> .bash_profile

nvm install v4.1.1
nvm use v4.1.1
nvm alias default 4.1.1