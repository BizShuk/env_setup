#!/bin/bash
set -euo pipefail

. "$(dirname "$0")/settings.sh"
# shellcheck source=./_lib_bash_plugin.sh
. "$(dirname "$0")/_lib_bash_plugin.sh"

# ctags 5.8 vendored 來源 (pkg/ctags-5.8) 已於 2026-07-09 結構清理時
# 改為 git submodule (見 .gitmodules), 改用 Homebrew 安裝 universal-ctags。
# 若需保留 5.8 自行編譯行為, 請:
#   1. git submodule update --init --recursive
#   2. 將下方 brew 區塊註解, 改用原本的 ./configure + make

ctags_pkg="universal-ctags"

if ! command -v ctags >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1; then
        echo "Installing ${ctags_pkg} via Homebrew..."
        brew install "${ctags_pkg}"
    else
        echo "ERROR: 'brew' not found; install Homebrew or build ctags-5.8 manually from pkg/ctags-5.8 submodule." >&2
        exit 1
    fi
else
    echo "ctags already installed: $(command -v ctags)"
fi

# 清理舊版 ctags_setup.sh 重複寫入之 $USER_LIB/bin 路徑 (bin/bash/.bashrc 已全域設定 ~/.local/bin)
update_bash_plugin_block "ctags" \
    '/^export PATH=\$PATH:.*\.local\/bin$/d' \
    '/^export PATH=\$PATH:\$USER_LIB\/bin$/d' <<EOF
EOF
