#!/bin/bash

. "$(dirname "$0")/settings.sh"

ctags_ver="5.8"

pushd "$REPO_DIR/pkg/ctags-${ctags_ver}" || exit
    ./configure --prefix="$USER_LIB"
    make
    sudo make install
    make distclean
popd || exit


echo "export PATH=\$PATH:$USER_LIB/bin" >> $INSTALL_DIR/.bash_plugin
