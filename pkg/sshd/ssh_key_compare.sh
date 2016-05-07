#!/bin/bash

. ./settings.sh

private=`ssh-keygen -y -f $idir/.ssh/id_rsa | cut -d ' ' -f 1,2`
public=`cat $idir/.ssh/id_rsa.pub | cut -d ' ' -f 1,2`

if [ "$private" == "$public" ]; then
    echo key id matched
else
    echo key is not matched
fi


