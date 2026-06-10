#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/settings.sh"

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

echo -e "\n# OpenSSL" >> "$INSTALL_DIR"/.bash_plugin
echo "export PATH=$OPENSSL_LIB_PATH/bin:\$PATH" >> "$INSTALL_DIR"/.bash_plugin
echo "export MANPATH=$OPENSSL_LIB_PATH/share/man:\$MANPATH" >> "$INSTALL_DIR"/.bash_plugin
