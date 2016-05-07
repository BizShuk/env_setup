#!/bin/bash

. ./settings.sh

sudo cp $pkg_sdir/sshd/sshd_config /etc/ssh/sshd_config
sudo cp $pkg_sdir/sshd/ssh_config  /etc/ssh/ssh_config
