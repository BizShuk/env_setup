#!/bin/bash

source settings.sh

ctags_ver="5.8"

pushd $repo_dir/lib/ctag-${ctags_ver}
    ./configure
    make
    sudo make install
popd
