#!/bin/bash

# customized parameter
user="shuk"
passwd="zxcvasdf"
email="biz.shuk@gmail.com"

# darwin for Mac , linux for ubuntu, linux, ...
os=$( uname | tr '[:upper:]' '[:lower:]')
KERNEL_NAME=$(uname -s)
KERNEL_VER=$(uname -r)
CPU_ARCH=$(uname -m)


# Install path
INSTALL_DIR=$HOME;

# env_setup path
REPO_DIR=$INSTALL_DIR/env_setup;
REPO_PKG=$REPO_DIR/pkg

# User-releated folders
USER_BIN=$INSTALL_DIR/bin
USER_LIB=$INSTALL_DIR/lib
USER_LOG=$INSTALL_DIR/log
USER_PROJECT=$USER_PROJECT
USER_TMP=$USER_TMP


# structure setup
setup_structure(){
    [ ! -d $USER_BIN              ]     && mkdir $USER_BIN      2>/dev/nll;
    [ ! -d $USER_LIB              ]     && mkdir $USER_LIB      2>/dev/nul;
    [ ! -d $USER_LOG              ]     && mkdir $USER_LOG      2>/dev/null;
    [ ! -d $USER_PROJECT          ]     && mkdir $USER_PROJECT  2>/dev/null;
    [ ! -d $USER_TMP              ]     && mkdir $USER_TMP      2>/dev/null;
}


