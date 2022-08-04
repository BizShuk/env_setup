#!/bin/bash

. ./settings.sh

ctags_ver="5.8"

pushd $REPO_DIR/pkg/ctags-${ctags_ver}
    ./configure --prefix="$USER_LIB"
    make
    sudo make install
    make distclean
popd


echo "export PATH=\$PATH:$USER_LIB/bin" >> $INSTALL_DIR/.bash_plugin
