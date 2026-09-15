#!/bin/bash
set -euo pipefail

# ============================================================================
# ollama.sh — Install Ollama LLM toolchain and configure environment
# ============================================================================
# Installs ollama via Homebrew on macOS, configures OLLAMA_KEEP_ALIVE=5m and
# OLLAMA_MAX_LOADED_MODELS=1 in ~/.bash_plugin and launchctl, handles
# transition from brew services to PM2 management, and prompts to download
# default model (qwen3.5:4b-q4_K_M).
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/settings.sh"
# shellcheck source=./_lib_bash_plugin.sh
source "${SCRIPT_DIR}/_lib_bash_plugin.sh"

if [ "$(uname -s)" != "Darwin" ]; then
    echo "Notice: ollama.sh is primarily optimized for macOS (current: $(uname -s))."
fi

if ! command -v brew >/dev/null 2>&1; then
    echo "ERROR: Homebrew is required to install ollama. Please run ./scripts/brew.sh first." >&2
    exit 1
fi

# 1. Install or verify Ollama
if ! command -v ollama >/dev/null 2>&1; then
    echo "Installing ollama via Homebrew..."
    brew install ollama
else
    echo "ollama is already installed: $(command -v ollama) ($(ollama --version 2>/dev/null || true))"
fi

# 2. Configure environment variables in ~/.bash_plugin
echo "Configuring Ollama environment variables in ~/.bash_plugin..."
update_bash_plugin_block "ollama" \
    '/^export OLLAMA_KEEP_ALIVE=/d' \
    '/^export OLLAMA_MAX_LOADED_MODELS=/d' <<'EOF'
export OLLAMA_KEEP_ALIVE="5m"
export OLLAMA_MAX_LOADED_MODELS=1
EOF

# 3. Apply environment variables to macOS launchd session
if [ "$(uname -s)" = "Darwin" ]; then
    echo "Setting macOS launchctl session environment variables..."
    launchctl setenv OLLAMA_KEEP_ALIVE "5m"
    launchctl setenv OLLAMA_MAX_LOADED_MODELS "1"
fi

# 4. Handle transition from brew services to PM2 to avoid port conflicts
if command -v brew >/dev/null 2>&1 && brew services list 2>/dev/null | grep -q "^ollama[[:space:]]\+started"; then
    echo "Disabling legacy brew services ollama to prevent port conflict (11434) with PM2..."
    brew services stop ollama || true
fi

# 5. Ensure Ollama server is accessible before model operations
if ! ollama list >/dev/null 2>&1; then
    if command -v pm2 >/dev/null 2>&1; then
        echo "Starting Ollama server via PM2..."
        pm2 apply >/dev/null 2>&1 || true
        sleep 2
    fi
fi

# 6. Ask whether to download qwen3.5:4b-q4_K_M
DEFAULT_MODEL="qwen3.5:4b-q4_K_M"
AUTO_CONFIRM=false
for arg in "$@"; do
    case "$arg" in
        -y|--yes) AUTO_CONFIRM=true ;;
    esac
done

if ollama list 2>/dev/null | awk '{print $1}' | grep -q "^${DEFAULT_MODEL}$"; then
    echo "Model '${DEFAULT_MODEL}' is already downloaded."
    if [ "$AUTO_CONFIRM" = true ]; then
        echo "Auto-confirm enabled: re-pulling ${DEFAULT_MODEL}..."
        ollama pull "${DEFAULT_MODEL}"
    else
        printf "Model '%s' is already downloaded. Do you want to re-download/update it? [y/N]: " "${DEFAULT_MODEL}"
        if ! read -r ans; then
            echo ""
            ans="n"
        elif [ ! -t 0 ]; then
            echo "${ans}"
        fi
        if [[ "${ans}" =~ ^[Yy]$ ]]; then
            echo "Pulling model '${DEFAULT_MODEL}'..."
            ollama pull "${DEFAULT_MODEL}"
        fi
    fi
else
    should_download=false
    if [ "$AUTO_CONFIRM" = true ]; then
        should_download=true
    else
        printf "Do you want to download model '%s'? [y/N]: " "${DEFAULT_MODEL}"
        if ! read -r ans; then
            echo ""
            ans="n"
        elif [ ! -t 0 ]; then
            echo "${ans}"
        fi
        if [[ "${ans}" =~ ^[Yy]$ ]]; then
            should_download=true
        fi
    fi

    if [ "$should_download" = true ]; then
        echo "Downloading model '${DEFAULT_MODEL}'..."
        ollama pull "${DEFAULT_MODEL}"
    else
        echo "Skipped downloading '${DEFAULT_MODEL}'."
    fi
fi

echo "Ollama setup complete."
if command -v pm2 >/dev/null 2>&1; then
    echo "To manage Ollama via PM2, execute: pm2 list / pm2 logs Ollama"
fi
