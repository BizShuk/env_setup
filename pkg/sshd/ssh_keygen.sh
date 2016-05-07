#!/bin/bash

. ./settings.sh

ssh-keygen -t rsa -b 4096 -C "$email"
cat $idir/.ssh/id_rsa.pub >> $idir/.ssh/authorized_keys
cat $idir/.ssh/id_rsa.pub >> $pkg_sdir/sshd/.ssh/id_rsa.pub
cat $idir/.ssh/authorized_keys >> $pkg_sdir/sshd/.ssh/authorized_keys
cat $idir/.ssh/id_rsa >> $pkg_sdir/sshd/.ssh/id_rsa




echo 'ssh-copy-id -i .ssh/id_rsa.pub <hostname> to copy pubkey to remote' 
