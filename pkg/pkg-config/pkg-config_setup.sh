#!/bin/bash

pkg-config_ver="0.28"
pkg-config_name="pkg-config-${pkg-config_ver}"




tmpdir=`mktemp -d`

pushd "$tmpdir"
    wget http://pkgconfig.freedesktop.org/releases/${pkg-config_name}.tar.gz

    tar -zxvf ${pkg-config_name}.tar.gz

    pushd ${pkg-config_name}
        ./configure  --with-internal-glib
        make 
        sudo make install
    popd

popd
rm -rf "$tmpdir"
