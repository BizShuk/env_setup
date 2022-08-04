#!/bin/bash

. ./settings.sh

sudo cp $REPO_PKG/sshd/sshd_config /etc/ssh/sshd_config
sudo cp $REPO_PKG/sshd/ssh_config  /etc/ssh/ssh_config
