#!/bin/bash

# Darwin for Mac , Linux for ubuntu, linux, ...
os=$(uname)


# env path
idir=$HOME;                 # install dir
repo_dir=$idir/env_setup;   # source dir
sdir=$repo_dir



# docker 
docker_remote_server="10.128.112.15:5000"



genpasswd(){
    local l=$1
    [ "$1" == "" ] && l=16    

    tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${1} | xargs

}

