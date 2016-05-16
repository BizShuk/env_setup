#!/bin/bash

. ./settings.sh

ctags_ver="5.8"

pushd $sdir/pkg/ctags-${ctags_ver}
    ./configure --prefix="$lib_dir"
    make
    sudo make install
    make distclean
popd


echo "export PATH=\$PATH:$lib_dir/bin" >> $idir/.bash_plugin
