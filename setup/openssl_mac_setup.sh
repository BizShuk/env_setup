#!/bin/bash

source settings.sh

OPENSSL_VER="1_1_1q"
OPEN_SSL_FULLVER="OpenSSL_${OPENSSL_VER}.tar.gz"
OPENSSL_PATH="$INSTALL_DIR/lib/openssl"

cd $USER_LIB
# Warning: It redirect download link in Github, -L option is required. -O option is for remote-name
curl -LO https://github.com/openssl/openssl/archive/refs/tags/${OPEN_SSL_FULLVER}
tar -xzvf ${OPEN_SSL_FULLVER}
cd openssl-${OPEN_SSL_FULLVER%.tar.gz}

./configure darwin64-x86_64-cc --prefix=${OPENSSL_PATH}
make
make install

echo "# openssl" >> $INSTALL_DIR/.bash_plugin
echo "export PATH=$openssl_path/bin:\$PATH" >> $INSTALL_DIR/.bash_plugin
echo "export MANPATH=$openssl_path/ssl/man:\$MANPATH" >> $INSTALL_DIR/.bash_plugin
