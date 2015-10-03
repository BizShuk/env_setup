#!/bin/bash


# parameters
mode=$1

os=$(uname)

case $mode in
    "update")
        mode="update"
    ;;
    *)
        mode="server"      
    ;;
esac


echo "runngin $mode mode ......"


if [ "$mode" == "server" ]; then

	# update 
	apt-get install update && apt-get install upgrade -y
	
	# install package
	apt-get install git vim curl wget build-essential screen -y
fi


# env path
idir=$HOME;
repo_dir=$idir/env_setup;


# structure setup
mkdir $idir/bin;
mkdir $idir/lib;
mkdir $idir/logs;


bash_file=".bashrc";

# migrate configuration
if [ "$os" == "Darwin" ]; then
    bash_file=".bash_profile"
fi

[ "$mode" == "server" ] && action="cp -fr"
[ "$mode" == "update" ] && action="ln -sf"

$action $repo_dir/.bashrc ~/$bash_file;
. $bash_file;

echo 'PATH=${HOME}/bin:$PATH;' >> $idir/$bash_file;


$action $repo_dir/.bash_logout $idir/;
$action $repo_dir/.vimrc $idir/;
$action $repo_dir/.gitconfig $idir/;
$action $repo_dir/.vim $idir/.vim;

exit 0;




