#!/bin/bash

# customized parameter
user="shuk"
passwd="zxcvasdf"
email="biz.shuk@gmail.com"

# darwin for Mac , linux for ubuntu, linux, ...
os=$( uname | tr '[:upper:]' '[:lower:]')
kernel_name=$(uname -s)
kernel_version=$(uname -r)
cpu_arch=$(uname -m)


# env path
idir=$HOME;                 # install dir
repo_dir=$idir/env_setup;   # source dir
sdir=$repo_dir
pkg_sdir=$sdir/pkg
conf_sdir=$sdir/config

# installed dir
bin_dir=$idir/bin
lib_dir=$idir/lib
log_dir=$idir/log
project_dir=$idir/project
server_dir=$idir/server




# Go env
go_version="1.15.5"
go_arch=""
case "${cpu_arch}" in
    i386)
        go_arch="386"
    ;;
    armv6l)
        go_arch=${cpu_arch}
    ;;
    *)
        go_arch="amd64" # x86_64
    ;;
esac

go_fullversion="go${go_version}.${os}-${go_arch}"
go_root="$lib_dir/$go_fullversion"  # go package dir
go_path="$project_dir/go_project"   # go source dir
go_project=$go_path                 # go project


# structure setup
setup_structure(){
    [ ! -d $bin_dir               ]     && mkdir $bin_dir 2>/dev/null ;
    [ ! -d $lib_dir               ]     && mkdir $lib_dir 2>/dev/null ;
    [ ! -d $log_dir               ]     && ln -s $conf_sdir/log $log_dir 2>/dev/null ;
    [ ! -d $project_dir           ]     && mkdir $project_dir 2>/dev/null ;
    [ ! -d $server_dir            ]     && mkdir $server_dir 2>/dev/null ;
    [ ! -d $server_dir/samba/mnt1 ]     && mkdir -p $server_dir/samba/mnt1 2>/dev/null ;
    [ ! -d $idir/tmp ]  && mkdir $idir/tmp 2>/dev/null ;
    [ -d $idir/Desktop ] && mv $idir/Downloads $idir/Downloads.bak && ln -sf $idir/Desktop $idir/Downloads;

}


