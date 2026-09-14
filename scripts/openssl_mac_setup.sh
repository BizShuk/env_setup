#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/settings.sh"
# shellcheck source=./_lib_bash_plugin.sh
source "$(dirname "$0")/_lib_bash_plugin.sh"

if [ "$(uname -s)" != "Darwin" ]; then
    echo "Notice: openssl_mac_setup.sh is intended for macOS only (current: $(uname -s)). Skipping."
    exit 0
fi

OPENSSL_VER="3.0.13"
OPENSSL_TAR="openssl-${OPENSSL_VER}.tar.gz"
OPENSSL_INSTALL_PATH="${USER_LIB}/openssl-${OPENSSL_VER}"
OPENSSL_LIB_PATH="${USER_LIB}/openssl"

if command -v brew &>/dev/null; then
    echo "Homebrew detected. Installing OpenSSL@3 via Homebrew..."
    brew install openssl@3
    OPENSSL_BREW_PATH=$(brew --prefix openssl@3)
    ln -sf "$OPENSSL_BREW_PATH" "$OPENSSL_LIB_PATH"
else
    echo "Homebrew not detected. Compiling OpenSSL from source..."
    cd "$USER_LIB" || exit
    curl -LO https://www.openssl.org/source/${OPENSSL_TAR}
    tar -xzvf ${OPENSSL_TAR}
    cd openssl-${OPENSSL_VER} || exit

    ARCH_TARGET="darwin64-x86_64-cc"
    if [ "$(uname -m)" = "arm64" ]; then
        ARCH_TARGET="darwin64-arm64-cc"
    fi

    ./Configure $ARCH_TARGET --prefix="${OPENSSL_INSTALL_PATH}"
    make -j
    make install
    ln -sf "${OPENSSL_INSTALL_PATH}" "${OPENSSL_LIB_PATH}"
    cd .. || exit 1
    rm -rf openssl-${OPENSSL_VER}
    rm -f ${OPENSSL_TAR}
fi
update_bash_plugin_block "openssl" \
    '/^# OpenSSL$/d' \
    '/^# \[openssl\]$/d' \
    '/^export PATH=.*\/openssl\/bin/d' \
    '/^export MANPATH=.*\/openssl/d' <<EOF
export PATH="${OPENSSL_LIB_PATH}/bin:\${PATH}"
export MANPATH="${OPENSSL_LIB_PATH}/share/man:\${MANPATH:-}"
EOF
