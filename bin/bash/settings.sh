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
export USER_PROJECT=${HOME}/projects
[ ! -d "$USER_PROJECT" ] && mkdir "$USER_PROJECT"


export USER_BIN=${HOME}/bin
export USER_LIB=${HOME}/.local
export USER_LOCAL=${HOME}/.local
export USER_LOCAL_BIN=${HOME}/.local/bin
export USER_LOG=${HOME}/logs
export USER_TMP=${HOME}/tmp


[ ! -e "$USER_BIN" ] && ln -s "$USER_PROJECT/env_setup/bin" "$USER_BIN"

[ ! -e "$USER_LIB" ] && ln -s "$USER_LIB" "${HOME}/projects/env_setup/config/"


# env_setup path
export REPO_DIR=${USER_PROJECT}/env_setup
export REPO_PKG=${REPO_DIR}/pkg
export REPO_SETUP=${REPO_DIR}/setup


# system folder
[ ! -d "/etc/local" ] && sudo mkdir "/etc/local"
export SYSTEMD_DIR=/etc/systemd/system