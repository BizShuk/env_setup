#!/bin/bash

source ./settings.sh

ssh-keygen -t rsa -b 4096 -C "${email}"
cat "${INSTALL_DIR}/.ssh/id_rsa.pub" >>"${INSTALL_DIR}/.ssh/authorized_keys"
cat "${INSTALL_DIR}/.ssh/id_rsa.pub" >>"${REPO_PKG}/sshd/.ssh/id_rsa.pub"
cat "${INSTALL_DIR}/.ssh/authorized_keys" >>"${REPO_PKG}/sshd/.ssh/authorized_keys"
cat "${INSTALL_DIR}/.ssh/id_rsa" >>"${REPO_PKG}/sshd/.ssh/id_rsa"

echo 'ssh-copy-id -i .ssh/id_rsa.pub <hostname> to copy pubkey to remote'
