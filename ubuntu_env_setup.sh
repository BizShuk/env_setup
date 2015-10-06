#!/bin/bash

# update 
apt-get install update && apt-get install upgrade -y

# install package
apt-get install git vim curl wget build-essential screen -y


# env path
idir=$HOME;
repo_dir=$idir/env_setup;


# structure setup
mkdir $idir/bin;
mkdir $idir/lib;
mkdir $idir/logs;



ln -sf $repo_dir/.bashrc $idir/;
ln -sf $repo_dir/.bash_logout $idir/;
ln -sf $repo_dir/.vimrc $idir/;
ln -sf $repo_dir/.gitconfig $idir/;
ln -sf $repo_dir/.vim $idir/.vim;



exit 0;




