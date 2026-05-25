#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/settings.sh"

safe_link() {
    local src="$1"
    local dest="$2"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        echo "Backing up existing non-symlink file: $dest to $dest.bak"
        mv "$dest" "$dest.bak"
    fi
    ln -sf "$src" "$dest"
}

### [bash config alias] ###
safe_link "${REPO_DIR}/bin/bash/settings.sh" "${INSTALL_DIR}/settings.sh"
safe_link "${REPO_DIR}/bin/bash/.bashrc" "${INSTALL_DIR}/.bashrc"
safe_link "${REPO_DIR}/bin/bash/.bash_aliases" "${INSTALL_DIR}/.bash_aliases"
safe_link "${REPO_DIR}/bin/bash/.bash_function" "${INSTALL_DIR}/.bash_function"
safe_link "${REPO_DIR}/bin/bash/.bash_logout" "${INSTALL_DIR}/.bash_logout"
safe_link "${REPO_DIR}/bin/bash/backup.ignore" "${INSTALL_DIR}/backup.ignore"

### [git] ###
safe_link "${REPO_DIR}/bin/bash/.gitignore" "${INSTALL_DIR}/.gitignore"
safe_link "${REPO_DIR}/bin/bash/.gitconfig" "${INSTALL_DIR}/.gitconfig"
safe_link "${REPO_DIR}/bin/bash/.gitmessage" "${INSTALL_DIR}/.gitmessage"

### [screen] ###
safe_link "${REPO_DIR}/bin/bash/.screenrc" "${INSTALL_DIR}/.screenrc"


### [vim] ###
safe_link "${REPO_DIR}/bin/bash/.vimrc" "${INSTALL_DIR}/.vimrc"
safe_link "${REPO_DIR}/bin/bash/.vim" "${INSTALL_DIR}/.vim"

### [top] ###
safe_link "${REPO_DIR}/bin/bash/.toprc" "${INSTALL_DIR}/.toprc"

### [ssh] ###
mkdir "${INSTALL_DIR}/.ssh" 2>/dev/null
# cat "${REPO_PKG}/sshd/.ssh/id_rsa.pub" >> "${INSTALL_DIR}/.ssh/authorized_keys"

### for [mac] ###
safe_link "${INSTALL_DIR}/.bashrc" "${INSTALL_DIR}/.profile"

# Zsh support
if [ -f "${INSTALL_DIR}/.zshrc" ] || [[ "$SHELL" == *"zsh"* ]] || [ -n "$ZSH_VERSION" ]; then
    [ ! -f "${INSTALL_DIR}/.zshrc" ] && touch "${INSTALL_DIR}/.zshrc"
    if ! grep -q "bash_plugin" "${INSTALL_DIR}/.zshrc"; then
        echo -e "\n# Load env_setup plugin\n[ -f ~/.bash_plugin ] && source ~/.bash_plugin" >> "${INSTALL_DIR}/.zshrc"
    fi
fi
