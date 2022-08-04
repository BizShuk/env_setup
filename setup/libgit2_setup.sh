#!/bin/bash

source settings.sh



# Need cmake, pkg-config,


libgit2_ver="v0.24.1"

pushd $REPO_DIR/pkg/libgit2
    git reset --hard ${libgit2_ver}
    mkdir build && cd build

    # for cmake 3.0+ , a warning for project developer
    touch CMakeLists.txt
    echo "CMAKE_MINIMUM_REQUIRED(VERSION 2.6)" >> CMakeLists.txt
    echo "FIND_PACKAGE(Threads REQUIRED)" >> CMakeLists.txt

    cmake ..
    cmake -build .
    make
    sudo make install
popd
