#!/bin/bash


. ~/settings.sh
curl -L http://npmjs.org/install.sh | sh


echo "prefix = ${USER_LIB}/npm-global" > "${REPO_DIR}/bin/bash/.npmrc"
echo "export PATH=${USER_LIB}/.npm-global/bin:\$PATH >>~/.bash_plugin"

ln -sf "${REPO_DIR}/bin/bash/.npmrc" "${INSTALL_DIR}/"

