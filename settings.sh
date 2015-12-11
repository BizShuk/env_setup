#!/bin/bash

# Darwin for Mac , Linux for ubuntu, linux, ...
os=$(uname)


# env path
idir=$HOME;                 # install dir
repo_dir=$idir/env_setup;   # source dir
sdir=$repo_dir





# docker 
docker_remote_server="10.128.112.16:5000"


# structure setup
setup_structure(){
    [ ! -d $idir/bin  ] && mkdir $idir/bin;
    [ ! -d $idir/lib  ] && mkdir $idir/lib;
    [ ! -d $idir/logs ] && mkdir $idir/logs;
    [ ! -d $idir/projects ] && mkdir $idir/projects;
    [ ! -d $idir/servers ] && mkdir $idir/servers;
    [ ! -d $idir/servers/samba ] && mkdir $idir/servers/samba;
    [ ! -d $idir/servers/samba/mnt1 ] && mkdir $idir/servers/samba/mnt1;
}


genpasswd(){
    local l=$1
    [ "$1" == "" ] && l=16    

    tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${1} | xargs

}

