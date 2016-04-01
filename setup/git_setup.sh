#!/bin/bash
source settings.sh


sudo apt-get install libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev
sudo apt-get install asciidoc xmlto docbook2x


tmpdir=`mktemp -d`

pushd "$tmpdir"
    wget https://www.kernel.org/pub/software/scm/git/git-2.8.0.tar.gz
    tar zxf git-2.8.0.tar.gz
    rm git-2.8.0.tar.gz
    cd git-2.8.0.tar.gz
    make configure
    ./configure --prefix=/usr
    make all doc info
    sudo make install install-doc install-html install-info
popd
