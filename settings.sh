#!/bin/bash

# Darwin for Mac , Linux for ubuntu, linux, ...
os=$(uname)


# env path
idir=$HOME;                 # install dir
repo_dir=$idir/env_setup;   # source dir
sdir=$repo_dir

bin_dir=$idir/bin
lib_dir=$idir/lib
log_dir=$idir/log
project_dir=$idir/project
server_dir=$idir/server


go_version="go1.5.2.linux-amd64"
go_root="$bin_dir/go"               # go package dir
go_path="$project_dir/go_project"   # go source dir
go_project=$go_path                 # go project

# docker 
docker_remote_server="10.128.112.16:5000"


# structure setup
setup_structure(){
    [ ! -d $bin_dir               ] && mkdir $bin_dir;
    [ ! -d $lib_dir               ] && mkdir $lib_dir;
    [ ! -d $log_dir               ] && mkdir $log_dir;
    [ ! -d $project_dir           ] && mkdir $project_dir;
    [ ! -d $server_dir            ] && mkdir $server_dir;
    [ ! -d $server_dir/samba      ] && mkdir $server_dir/samba;
    [ ! -d $server_dir/samba/mnt1 ] && mkdir $server_dir/samba/mnt1;
}


genpasswd(){
    local l=$1
    [ "$1" == "" ] && l=16    

    tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${1} | xargs

}

