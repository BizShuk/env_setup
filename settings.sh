#!/bin/bash

# Darwin for Mac , Linux for ubuntu, linux, ...
os=$(uname)
os=$(echo $os | tr '[:upper:]' '[:lower:]')
kernel_name=$(uname -s)
kernel_version=$(uname -r)
cpu_arch=$(uname -m)




# env path
idir=$HOME;                 # install dir
repo_dir=$idir/env_setup;   # source dir
sdir=$repo_dir

bin_dir=$idir/bin
lib_dir=$idir/lib
log_dir=$idir/log
project_dir=$idir/project
server_dir=$idir/server


go_version="1.6"
go_arch=""
case "${cpu_arch}" in
    x86_64)
        go_arch="amd64"
    ;;
    i386)
        go_arch="386"
    ;;
    *)
        go_arch=${cpu_arch}
    ;;
esac

go_fullversion="go${go_version}.${os}-${go_arch}"
go_root="$lib_dir/$go_fullversion"      # go package dir
go_path="$project_dir/go_project"   # go source dir
go_project=$go_path                 # go project

# docker 
docker_remote_server="dr:5000"


# structure setup
setup_structure(){
    [ ! -d $bin_dir               ] && mkdir $bin_dir 2>/dev/null ;
    [ ! -d $lib_dir               ] && mkdir $lib_dir 2>/dev/null ;
    [ ! -d $log_dir               ] && mkdir $log_dir 2>/dev/null ;
    [ ! -d $project_dir           ] && mkdir $project_dir 2>/dev/null ;
    [ ! -d $server_dir            ] && mkdir $server_dir 2>/dev/null ;
    [ ! -d $server_dir/samba      ] && mkdir $server_dir/samba 2>/dev/null ;
    [ ! -d $server_dir/samba/mnt1 ] && mkdir $server_dir/samba/mnt1 2>/dev/null ;
}


genpasswd(){
    local l=$1
    [ "$1" == "" ] && l=16    

    tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${1} | xargs

}

