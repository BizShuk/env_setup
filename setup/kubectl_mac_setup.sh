#!/bin/bash

source settings.sh

setup_structure

KUBECTL_VER="v1.24.3"
echo Get current stable version by "curl -L -s https://dl.k8s.io/release/stable.txt"

cd ${USER_BIN} && curl -LO "https://dl.k8s.io/release/${KUBECTL_VER}/bin/darwin/amd64/kubectl"
chmod +x ${USER_BIN}/kubectl