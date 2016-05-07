#!/bin/bash

. ./settings.sh

ssh-keygen -t rsa -b 4096 -C "$email"
cat $idir/id_rsa.pub >> $idir/.ssh/authorized_keys

echo 'ssh-copy-id -i .ssh/id_rsa.pub <hostname> to copy pubkey to remote' 
