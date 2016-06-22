#!/bin/bash

. settings.sh

astyle_ver="2.05.1"
astyle_platform="linux"

astyle_path="${pkg_dir}/astyle/"
astyle_tar="astyle_${astyle_ver}_${astyle_platform}.tar.gz"


pushd ${astyle_path}
    tar -zxvf ${astyle_tar}
    cd astyle/build/gcc
    make
    make release
    sudo make install
    rm -rf astyle
popd





