#!/bin/bash

source settings.sh

OPENSSL_VER="1_0_2t"
OPENSSL_FULLVER="OpenSSL_${OPENSSL_VER}.tar.gz"
OPENSSL_INSTALL_PATH="${USER_LIB}/${OPENSSL_FULLVER%.tar.gz}"
OPENSSL_LIB_PATH="${USER_LIB}/openssl"

cd "$USER_LIB" || exit
# Warning: It redirect download link in Github, -L option is required. -O option is for remote-name
curl -LO https://github.com/openssl/openssl/archive/refs/tags/${OPENSSL_FULLVER}
tar -xzvf ${OPENSSL_FULLVER}
cd openssl-${OPENSSL_FULLVER%.tar.gz} || exit

./configure darwin64-x86_64-cc --prefix="${OPENSSL_INSTALL_PATH}"
make
make install
ln -sf "${OPENSSL_INSTALL_PATH}" "${OPENSSL_LIB_PATH}"

echo "# OpenSSL" >> "$INSTALL_DIR"/.bash_plugin
echo "export PATH=$OPENSSL_LIB_PATH/bin:\$PATH" >> "$INSTALL_DIR"/.bash_plugin
echo "export MANPATH=$OPENSSL_LIB_PATH/ssl/man:\$MANPATH" >> "$INSTALL_DIR"/.bash_plugin
