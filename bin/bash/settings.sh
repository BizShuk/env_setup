#!/bin/bash

# set -x # enable for printing executed command

# customized parameter
user="$(whoami)"
export user

export passwd="zxcvasdf"
export email="biz.shuk@gmail.com"

# darwin for Mac , linux for ubuntu, linux, ...
os=$(uname | tr '[:upper:]' '[:lower:]')
OS=${os}
export os
export OS

KERNEL_NAME=$(uname -s)
KERNEL_VER=$(uname -r)
export KERNEL_NAME
export KERNEL_VER

CPU_ARCH=$(uname -m)
export CPU_ARCH

ARCH=${CPU_ARCH}
# if ARCH equals to "x84_64", replace it with "amd64"
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
fi
export ARCH

# Install path
INSTALL_DIR=${HOME}



# User-releated folders
export USER_PROJECT=${INSTALL_DIR}/projects
[ ! -d "$USER_PROJECT" ] && mkdir "$USER_PROJECT"


export USER_BIN=${INSTALL_DIR}/bin
export USER_LIB=${INSTALL_DIR}/lib
export USER_LOG=${INSTALL_DIR}/logs
export USER_TMP=${INSTALL_DIR}/tmp


[ ! -e "$USER_BIN" ] && ln -s "$USER_PROJECT/env_setup/bin" "$USER_BIN"

[ ! -e "$USER_PROJECT/env_setup/tmp/lib" ] && mkdir "$USER_PROJECT/env_setup/tmp/lib"
[ ! -e "$USER_PROJECT/env_setup/tmp/logs" ] && mkdir "$USER_PROJECT/env_setup/tmp/logs"
[ ! -e "$USER_PROJECT/env_setup/tmp/tmp" ] && mkdir "$USER_PROJECT/env_setup/tmp/tmp"

[ ! -e "$USER_LIB" ] && ln -s "$USER_PROJECT/env_setup/tmp/lib" "$USER_LIB"
[ ! -e "$USER_LOG" ] && ln -s "$USER_PROJECT/env_setup/tmp/logs" "$USER_LOG"
[ ! -e "$USER_TMP" ] && ln -s "$USER_PROJECT/env_setup/tmp/tmp" "$USER_TMP"


# env_setup path
export REPO_DIR=${USER_PROJECT}/env_setup
export REPO_PKG=${REPO_DIR}/pkg
export REPO_SETUP=${REPO_DIR}/setup


# system folder
[ ! -d "/etc/local" ] && sudo mkdir "/etc/local"
export SYSTEMD_DIR=/etc/systemd/system