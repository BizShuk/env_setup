#!/bin/bash
source settings.sh

# [structure setup]
[ ! -d "$USER_BIN" ] && mkdir "${USER_BIN}" 2>/dev/nll
[ ! -d "$USER_LIB" ] && mkdir "${USER_LIB}" 2>/dev/nul
[ ! -d "$USER_LOG" ] && mkdir "${USER_LOG}" 2>/dev/null
[ ! -d "$USER_PROJECT" ] && mkdir "${USER_PROJECT}" 2>/dev/null
[ ! -d "$USER_TMP" ] && mkdir "${USER_TMP}" 2>/dev/null

echo -e "\n# [Default USER_BIN]" >>"${INSTALL_DIR}"/.bash_plugin
echo export PATH="${USER_BIN}":\$PATH >>"${INSTALL_DIR}"/.bash_plugin

### [bash config alias] ###
ln -sf "${REPO_DIR}/config/.bashrc" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/config/.bash_aliases" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/config/.bash_function" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/config/.bash_logout" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/config/settings.sh" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/config/backup.ignore" "${INSTALL_DIR}/"

### [git] ###
ln -sf "${REPO_DIR}/pkg/git/.gitignore" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/pkg/git/.gitconfig" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/pkg/git/.gitmessage" "${INSTALL_DIR}/"

### [vim] ###
ln -sf "${REPO_DIR}/pkg/vim/.vimrc" "${INSTALL_DIR}/"
ln -sf "${REPO_DIR}/pkg/vim/.vim" "${INSTALL_DIR}/"

### [top] ###
ln -sf "${REPO_DIR}/pkg/top/.toprc" "${INSTALL_DIR}/"

### [ssh] ###
mkdir "${INSTALL_DIR}/.ssh" 2>/dev/null
# cat "${REPO_PKG}/sshd/.ssh/id_rsa.pub" >> "${INSTALL_DIR}/.ssh/authorized_keys"

### for [mac] ###
ln -sf "${INSTALL_DIR}/.bashrc" "${INSTALL_DIR}/.profile"

# ln for env_setup to project
if [ ! -d "${INSTALL_DIR}/env_setup" ] || [ ! -d "${USER_PROJECT}/env_setup" ]; then
    if [ -d "${INSTALL_DIR}/env_setup" ]; then
        ln -sf "${INSTALL_DIR}/env_setup" "${USER_PROJECT}/env_setup"
    else
        ln -sf "${USER_PROJECT}/env_setup" "${INSTALL_DIR}/env_setup"
    fi
fi

source "${INSTALL_DIR}/.bashrc"
