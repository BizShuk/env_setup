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
# Environment: bin/bash/settings.sh is the single source of REPO_DIR
# ----------------------------------------------------------------------------
# shellcheck source=bin/bash/settings.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bin/bash/settings.sh"

# ----------------------------------------------------------------------------
# Pre-flight: install Superset default tools (pm2, skills, dux, ...)
# ----------------------------------------------------------------------------
# shellcheck source=scripts/default_tools.sh
"${REPO_DIR}/scripts/default_tools.sh"

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
    ln -sf "${REPO_DIR}/bin/vscode/settings.json" \
           "$user_dir/settings.json"
    ln -sf "${REPO_DIR}/bin/vscode/keybindings.json" \
           "$user_dir/keybindings.json"
    rm -rf "$user_dir/snippets"
    ln -sf "${REPO_DIR}/bin/vscode/snippets" \
           "$user_dir/snippets"
}

# ----------------------------------------------------------------------------
# Ensure runtime dirs exist
# ----------------------------------------------------------------------------
mkdir -p "${REPO_DIR}/tmp"

# ----------------------------------------------------------------------------
# Symlink table: source -> target (relative to repo root, all under ./tmp/)
# ----------------------------------------------------------------------------
echo -e "${BLUE}Recreating symbolic links under ./tmp/...${NC}"

declare -a SYMLINKS=(
    # Global system configurations
    "/etc/fstab:${REPO_DIR}/tmp/fstab"
    "/etc/group:${REPO_DIR}/tmp/group"
    "/etc/hostname:${REPO_DIR}/tmp/hostname"
    "/etc/hosts:${REPO_DIR}/tmp/hosts"
    "/etc/localtime:${REPO_DIR}/tmp/localtime"
    "/etc/ssl/openssl.cnf:${REPO_DIR}/tmp/openssl.cnf"
    "/etc/passwd:${REPO_DIR}/tmp/passwd"
    "/etc/sysctl.conf:${REPO_DIR}/tmp/sysctl.conf"
    "/var/log/auth.log:${REPO_DIR}/tmp/auth.log"
    "/etc/ssh/ssh_config:${REPO_DIR}/tmp/ssh_config"

    # User home directory configurations
    "${HOME}/.bash_plugin:${REPO_DIR}/tmp/.bash_plugin"
    "${HOME}/.colima:${REPO_DIR}/tmp/.colima"
    "${HOME}/.config:${REPO_DIR}/tmp/.config"
    "${HOME}/.config/system:${REPO_DIR}/tmp/system"
    "${HOME}/.gemini:${REPO_DIR}/tmp/.gemini"
    "${HOME}/.screenrc:${REPO_DIR}/tmp/.screenrc"
    "${HOME}/.ssh:${REPO_DIR}/tmp/.ssh"
    "${HOME}/.vscode:${REPO_DIR}/tmp/.vscode"
    "${HOME}/lib:${REPO_DIR}/tmp/lib"
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
