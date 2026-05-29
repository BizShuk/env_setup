#!/bin/bash
set -e

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Recreating symbolic links in config/ directory...${NC}"

# Ensure parent directories exist
mkdir -p "${HOME}/projects/env_setup/config"

# Global system configurations
echo -e "${GREEN}Linking global configurations...${NC}"
ln -sf "/etc/fstab" "./config/fstab"
ln -sf "/etc/group" "./config/group"
ln -sf "/etc/hostname" "./config/hostname"
ln -sf "/etc/hosts" "./config/hosts"
ln -sf "/etc/localtime" "./config/localtime"
ln -sf "/etc/ssl/openssl.cnf" "./config/openssl.cnf"
ln -sf "/etc/passwd" "./config/passwd"
ln -sf "/etc/sysctl.conf" "./config/sysctl.conf"
ln -sf "/var/log/auth.log" "./config/auth.log"
ln -sf "/etc/ssh/ssh_config" "./config/ssh_config"

# User home directory configurations
echo -e "${GREEN}Linking user configurations...${NC}"
ln -sf "${HOME}/.bash_plugin" "./config/.bash_plugin"
ln -sf "${HOME}/.colima" "./config/.colima"
ln -sf "${HOME}/.config" "./config/.config"
ln -sf "${HOME}/.screenrc" "./config/.screenrc"
ln -sf "${HOME}/.ssh" "./config/.ssh"
ln -sf "${HOME}/.vscode" "./config/.vscode"
ln -sf "${HOME}/lib" "./config/lib"

# VSCode and Antigravity Configuration
echo -e "${BLUE}Configuring VSCode settings...${NC}"
if [ "$(uname)" = "Darwin" ]; then
    # macOS paths
    mkdir -p "${HOME}/Library/Application Support/Code/User"
    ln -sf "${HOME}/projects/env_setup/bin/vscode/settings.json" "${HOME}/Library/Application Support/Code/User/settings.json"
    ln -sf "${HOME}/projects/env_setup/bin/vscode/keybindings.json" "${HOME}/Library/Application Support/Code/User/keybindings.json"
    rm -rf "${HOME}/Library/Application Support/Code/User/snippets"
    ln -sf "${HOME}/projects/env_setup/bin/vscode/snippets" "${HOME}/Library/Application Support/Code/User/snippets"

    mkdir -p "${HOME}/Library/Application Support/Antigravity IDE/User"
    ln -sf "${HOME}/projects/env_setup/bin/vscode/settings.json" "${HOME}/Library/Application Support/Antigravity IDE/User/settings.json"
    ln -sf "${HOME}/projects/env_setup/bin/vscode/keybindings.json" "${HOME}/Library/Application Support/Antigravity IDE/User/keybindings.json"
    rm -rf "${HOME}/Library/Application Support/Antigravity IDE/User/snippets"
    ln -sf "${HOME}/projects/env_setup/bin/vscode/snippets" "${HOME}/Library/Application Support/Antigravity IDE/User/snippets"
elif [ "$(uname)" = "Linux" ]; then
    # Linux paths
    mkdir -p "${HOME}/.config/Code/User"
    ln -sf "${HOME}/projects/env_setup/bin/vscode/settings.json" "${HOME}/.config/Code/User/settings.json"
    ln -sf "${HOME}/projects/env_setup/bin/vscode/keybindings.json" "${HOME}/.config/Code/User/keybindings.json"
    rm -rf "${HOME}/.config/Code/User/snippets"
    ln -sf "${HOME}/projects/env_setup/bin/vscode/snippets" "${HOME}/.config/Code/User/snippets"

    mkdir -p "${HOME}/.config/Antigravity IDE/User"
    ln -sf "${HOME}/projects/env_setup/bin/vscode/settings.json" "${HOME}/.config/Antigravity IDE/User/settings.json"
    ln -sf "${HOME}/projects/env_setup/bin/vscode/keybindings.json" "${HOME}/.config/Antigravity IDE/User/keybindings.json"
    rm -rf "${HOME}/.config/Antigravity IDE/User/snippets"
    ln -sf "${HOME}/projects/env_setup/bin/vscode/snippets" "${HOME}/.config/Antigravity IDE/User/snippets"
fi

echo -e "${GREEN}All symbolic links have been recreated successfully!${NC}"
