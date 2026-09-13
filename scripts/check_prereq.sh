#!/bin/bash
set -euo pipefail

# ============================================================================
# check_prereq.sh — Check prerequisites for env_setup task runners
# ============================================================================
# Verifies:
#   1. Git CLI ready
#   2. Bash environment setup (dotfiles linked to repo, .bash_plugin present)
#   3. Node.js runtime & npm CLI ready in PATH
#   4. Platform package manager (Homebrew on macOS / apt-get on Linux)
#
# Exit status:
#   0: All prerequisites satisfied
#   1: One or more prerequisites missing
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/settings.sh"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FAILED=0
ERRORS=()

ok()   { echo -e "  ${GREEN}✔${NC} $1"; }
fail() { echo -e "  ${RED}✘${NC} $1"; FAILED=1; ERRORS+=("$2"); }
info() { echo -e "${BLUE}==>${NC} $1"; }

info "Checking system prerequisites (${OS}-${ARCH})..."

# 1. Git
if command -v git >/dev/null 2>&1; then
    ok "Git CLI: $(command -v git) ($(git --version | head -n1))"
else
    fail "Git CLI not found" "Install git (on macOS: xcode-select --install, on Linux: sudo apt-get install git)"
fi

# 2. Bash Env Setup
BASHRC_DEST="${INSTALL_DIR}/.bashrc"
BASHRC_SRC="${REPO_DIR}/bin/bash/.bashrc"

if [ -L "${BASHRC_DEST}" ]; then
    TARGET="$(readlink "${BASHRC_DEST}" || true)"
    if [[ "${TARGET}" == *"env_setup/bin/bash/.bashrc"* ]] || [ "${TARGET}" = "${BASHRC_SRC}" ]; then
        ok "Bash environment: ${BASHRC_DEST} -> ${TARGET}"
    else
        fail "Bash environment: ${BASHRC_DEST} points to ${TARGET} (expected ${BASHRC_SRC})" \
             "Run: ./scripts/bash_env_setup.sh (or npm run run:bash-env) to relink dotfiles"
    fi
elif [ -f "${BASHRC_DEST}" ]; then
    fail "Bash environment: ${BASHRC_DEST} exists but is not a symlink to repo" \
         "Run: ./scripts/bash_env_setup.sh (or npm run run:bash-env) to backup and link dotfiles"
else
    fail "Bash environment: ${BASHRC_DEST} not found" \
         "Run: ./scripts/bash_env_setup.sh (or npm run run:bash-env) to setup dotfiles"
fi

# Check .bash_plugin existence
if [ -f "${BASH_PLUGIN:-${HOME}/.bash_plugin}" ]; then
    ok "Bash plugin file: ${BASH_PLUGIN:-${HOME}/.bash_plugin}"
else
    fail "Bash plugin file not found (${BASH_PLUGIN:-${HOME}/.bash_plugin})" \
         "Touch or run ./scripts/bash_env_setup.sh"
fi

# 3. Node.js & NPM CLI
if command -v npm >/dev/null 2>&1 && command -v node >/dev/null 2>&1; then
    ok "Node.js runtime: $(node --version) ($(command -v node))"
    ok "NPM CLI: $(npm --version) ($(command -v npm))"
else
    # Check if NVM has node installed but not in current subshell PATH
    NVM_DIR="${USER_LIB}/nvm"
    if [ -s "${NVM_DIR}/nvm.sh" ]; then
        fail "Node.js / NPM CLI not in current PATH (NVM found at ${NVM_DIR})" \
             "Run: source ~/.bash_plugin or run: ./scripts/nodejs.sh to reconfigure"
    else
        fail "NPM CLI not found (node / npm missing in PATH)" \
             "Run: ./scripts/nodejs.sh to install Node.js and npm via NVM"
    fi
fi

# 4. OS Package Manager
if [ "${OS}" = "darwin" ]; then
    if command -v brew >/dev/null 2>&1; then
        ok "Homebrew CLI: $(command -v brew) ($(brew --version | head -n1))"
    elif [ -x "${USER_LOCAL}/homebrew/bin/brew" ]; then
        ok "Homebrew CLI (local): ${USER_LOCAL}/homebrew/bin/brew"
    else
        fail "Homebrew CLI not found" "Run: ./scripts/brew.sh to install Homebrew"
    fi
elif [ "${OS}" = "linux" ]; then
    if command -v apt-get >/dev/null 2>&1; then
        ok "APT package manager: $(command -v apt-get)"
    else
        fail "APT package manager not found" "Ensure you are on a Debian/Ubuntu system"
    fi
fi

echo ""
if [ "${FAILED}" -eq 0 ]; then
    echo -e "${GREEN}All prerequisites are satisfied! Ready to run npm-package tasks.${NC}"
    exit 0
else
    echo -e "${RED}Prerequisite check failed (${#ERRORS[@]} issue(s) detected):${NC}"
    for err in "${ERRORS[@]}"; do
        echo -e "  ${YELLOW}→ Action:${NC} ${err}"
    done
    exit 1
fi
