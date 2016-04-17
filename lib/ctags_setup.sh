#!/bin/bash

source settings.sh

ctags_ver="5.8"

pushd $repo_dir/lib/ctag-${ctags_ver}
    ./configure --prefix="$lib_dir"
    make
    sudo make install
    make distclean
popd
