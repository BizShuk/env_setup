#!/bin/bash
set -e

# ============================================================================
# env_setup — symlink bootstrap
# ============================================================================
# Recreates repo-local symlinks that point at global system configs and user
# home configs, then applies the bin/vscode/ profile to VSCode + Antigravity
# IDE on the current OS. All symlinks land under ./tmp/ (git-ignored).
# ============================================================================

# ----------------------------------------------------------------------------
# Pre-flight: install golang tools that other env_setup scripts rely on
# ----------------------------------------------------------------------------
go install github.com/bizshuk/pm2@master
go install github.com/bizshuk/skills@master

# ----------------------------------------------------------------------------
# Color output
# ----------------------------------------------------------------------------
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# ----------------------------------------------------------------------------
# Helper: link bin/vscode/ profile into a target IDE User directory
# ----------------------------------------------------------------------------
# Args:
#   $1 - path to the IDE's User directory
link_ide_config() {
    local user_dir="$1"
    mkdir -p "$user_dir"
    ln -sf "${HOME}/projects/env_setup/bin/vscode/settings.json" \
           "$user_dir/settings.json"
    ln -sf "${HOME}/projects/env_setup/bin/vscode/keybindings.json" \
           "$user_dir/keybindings.json"
    rm -rf "$user_dir/snippets"
    ln -sf "${HOME}/projects/env_setup/bin/vscode/snippets" \
           "$user_dir/snippets"
}

# ----------------------------------------------------------------------------
# Ensure runtime dirs exist
# ----------------------------------------------------------------------------
mkdir -p "${HOME}/projects/env_setup/tmp"

# ----------------------------------------------------------------------------
# Symlink table: source -> target (relative to repo root, all under ./tmp/)
# ----------------------------------------------------------------------------
echo -e "${BLUE}Recreating symbolic links under ./tmp/...${NC}"

declare -a SYMLINKS=(
    # Global system configurations
    "/etc/fstab:${HOME}/projects/env_setup/tmp/fstab"
    "/etc/group:${HOME}/projects/env_setup/tmp/group"
    "/etc/hostname:${HOME}/projects/env_setup/tmp/hostname"
    "/etc/hosts:${HOME}/projects/env_setup/tmp/hosts"
    "/etc/localtime:${HOME}/projects/env_setup/tmp/localtime"
    "/etc/ssl/openssl.cnf:${HOME}/projects/env_setup/tmp/openssl.cnf"
    "/etc/passwd:${HOME}/projects/env_setup/tmp/passwd"
    "/etc/sysctl.conf:${HOME}/projects/env_setup/tmp/sysctl.conf"
    "/var/log/auth.log:${HOME}/projects/env_setup/tmp/auth.log"
    "/etc/ssh/ssh_config:${HOME}/projects/env_setup/tmp/ssh_config"

    # User home directory configurations
    "${HOME}/.bash_plugin:${HOME}/projects/env_setup/tmp/.bash_plugin"
    "${HOME}/.colima:${HOME}/projects/env_setup/tmp/.colima"
    "${HOME}/.config:${HOME}/projects/env_setup/tmp/.config"
    "${HOME}/.gemini:${HOME}/projects/env_setup/tmp/.gemini"
    "${HOME}/.screenrc:${HOME}/projects/env_setup/tmp/.screenrc"
    "${HOME}/.ssh:${HOME}/projects/env_setup/tmp/.ssh"
    "${HOME}/.vscode:${HOME}/projects/env_setup/tmp/.vscode"
    "${HOME}/lib:${HOME}/projects/env_setup/tmp/lib"
)

for link_pair in "${SYMLINKS[@]}"; do
    IFS=':' read -r source_path target_path <<<"$link_pair"

    if [ -L "$target_path" ]; then
        rm "$target_path"
    elif [ -e "$target_path" ]; then
        echo -e "${BLUE}Warning: $target_path exists but is not a symlink. Skipping...${NC}"
        continue
    fi

    echo -e "${GREEN}Linking: $source_path -> $target_path${NC}"
    ln -s "$source_path" "$target_path"
done

# ----------------------------------------------------------------------------
# Apply VSCode + Antigravity IDE profile
# ----------------------------------------------------------------------------
echo -e "${BLUE}Configuring IDE settings...${NC}"

case "$(uname)" in
    Darwin)
        link_ide_config "${HOME}/Library/Application Support/Code/User"
        link_ide_config "${HOME}/Library/Application Support/Antigravity IDE/User"
        ;;
    Linux)
        link_ide_config "${HOME}/.config/Code/User"
        link_ide_config "${HOME}/.config/Antigravity IDE/User"
        ;;
esac

echo -e "${GREEN}All symbolic links have been recreated successfully!${NC}"
