#!/bin/bash


tmpdir=`mktemp -d`


sudo apt-get install -y ruby-dev libperl-dev python3-dev

pushd "$tmpdir"
    wget https://github.com/vim/vim/archive/v7.4.1692.tar.gz
    tar zxf v7.4.1692.tar.gz 
    cd vim-7.4.1692
    ./configure --enable-python3interp \ 
    --with-python3-config-dir=/usr/lib/python3.4/config-3.4m-x86_64-linux-gnu/ \
        --enable-perlinterp \
        --enable-rubyinterp \
        --with-features=huge \
        --enable-cscope \
        -j8 \ 
        --prefix=/usr
    make -j8
    sudo make install
popd
rm -r "$tmpdir"

echo check :py3 print("yes") and edit tmp.c with for snippets

