#!/bin/bash

source settings.sh

tmpdir=`mktemp -d`


pushd "$tmpdir"
    wget https://github.com/vim/vim/archive/v7.4.1692.tar.gz
    tar zxf v7.4.1692.tar.gz
    cd vim-7.4.1692
    ./configure --enable-pythoninterp \
        --with-python-config-dir=/usr/lib/python2.7/config \
        --enable-perlinterp \
        --with-features=huge \
        --enable-cscope \
        --prefix=/usr
    make
    sudo make install
popd
# --enable-python3interp
# --with-python3-config-dir



# for ctag
pushd $repo_dir/lib/ctag-5.8
    ./configure
    make
    sudo make install
popd


echo check :py3 print("yes") and edit tmp.c with for snippets

