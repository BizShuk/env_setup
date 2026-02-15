#!/usr/bin/env bash

openssl_ver="1.1.0"
openssl="openssl-${openssl_ver}"

wget https://www.openssl.org/source/${openssl}.tar.gz

tar zxvf ${openssl}.tar.gz

pushd $openssl || exit
    ./config
    make -j
    sudo make install
popd || exit
rm -r ${openssl}
rm ${openssl}.tar.gz
