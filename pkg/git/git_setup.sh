#!/bin/bash
source settings.sh


GIT_VERSION=${GIT_VERSION:-2.32.0}
GIT_DISTRIBUTION="git-${GIT_VERSION}"

sudo apt-get install libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev
sudo apt-get install asciidoc xmlto docbook2x


tmpdir=`mktemp -d`

pushd "$tmpdir"
    wget https://www.kernel.org/pub/software/scm/git/${GIT_DISTRIBUTION}.tar.gz
    tar zxf ${GIT_DISTRIBUTION}.tar.gz
    rm ${GIT_DISTRIBUTION}.tar.gz
    cd ${GIT_DISTRIBUTION}
    make configure
    ./configure --prefix=/usr
    make all doc info
    sudo make install install-doc install-html install-info
popd
