#!/bin/bash

# customized parameter
user="$(whoami)"
export user

export passwd="zxcvasdf"
export email="biz.shuk@gmail.com"

# darwin for Mac , linux for ubuntu, linux, ...
os=$(uname | tr '[:upper:]' '[:lower:]')
export os

KERNEL_NAME=$(uname -s)
export KERNEL_NAME

KERNEL_VER=$(uname -r)
export KERNEL_VER

CPU_ARCH=$(uname -m)
export CPU_ARCH

# Install path
INSTALL_DIR=${HOME}

# env_setup path
export REPO_DIR=${INSTALL_DIR}/env_setup
export REPO_PKG=${REPO_DIR}/pkg

# User-releated folders
export USER_BIN=${INSTALL_DIR}/bin
export USER_LIB=${INSTALL_DIR}/lib
export USER_LOG=${INSTALL_DIR}/logs
export USER_PROJECT=${INSTALL_DIR}/projects
export USER_TMP=${INSTALL_DIR}/tmp
