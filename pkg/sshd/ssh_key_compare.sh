#!/bin/bash

. ./settings.sh

private=`ssh-keygen -y -f $INSTALL_DIR/.ssh/id_rsa | cut -d ' ' -f 1,2`
public=`cat $INSTALL_DIR/.ssh/id_rsa.pub | cut -d ' ' -f 1,2`

if [ "$private" == "$public" ]; then
    echo key id matched
else
    echo key is not matched
fi


