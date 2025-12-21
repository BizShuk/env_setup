#!/bin/bash
source settings.sh

### [bash config alias] ###
ln -sf "${REPO_DIR}/bin/bash/settings.sh" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/bin/bash/.bashrc" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/bin/bash/.bash_aliases" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/bin/bash/.bash_function" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/bin/bash/.bash_logout" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/bin/bash/backup.ignore" "${INSTALL_DIR}/"

### [git] ###
ln -sf "${REPO_DIR}/bin/bash/.gitignore" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/bin/bash/.gitconfig" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/bin/bash/.gitmessage" "${INSTALL_DIR}/"

### [screen] ###
ln -sf "${REPO_DIR}/bin/bash/.screenrc" "${INSTALL_DIR}/"


### [vim] ###
ln -sf "${REPO_DIR}/bin/bash/.vimrc" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/bin/bash/.vim" "${INSTALL_DIR}/"

### [top] ###
ln -sf "${REPO_DIR}/bin/bash/.toprc" "${INSTALL_DIR}/"

### [ssh] ###
mkdir "${INSTALL_DIR}/.ssh" 2>/dev/null
# cat "${REPO_PKG}/sshd/.ssh/id_rsa.pub" >> "${INSTALL_DIR}/.ssh/authorized_keys"

### for [mac] ###
ln -sf "${INSTALL_DIR}/.bashrc" "${INSTALL_DIR}/.profile"
