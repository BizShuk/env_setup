#!/bin/bash

# customized parameter
user=$(whoami)
passwd="zxcvasdf"
email="biz.shuk@gmail.com"

# darwin for Mac , linux for ubuntu, linux, ...
os=$(uname | tr '[:upper:]' '[:lower:]')
KERNEL_NAME=$(uname -s)
KERNEL_VER=$(uname -r)
CPU_ARCH=$(uname -m)

# Install path
INSTALL_DIR=${HOME}

# env_setup path
REPO_DIR=${INSTALL_DIR}/env_setup
REPO_PKG=${REPO_DIR}/pkg

# User-releated folders
USER_BIN=${INSTALL_DIR}/bin
USER_LIB=${INSTALL_DIR}/lib
USER_LOG=${INSTALL_DIR}/log
USER_PROJECT=${INSTALL_DIR}/project
USER_TMP=${INSTALL_DIR}/tmp
