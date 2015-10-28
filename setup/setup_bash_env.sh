#!/bin/bash



# env path
idir=$HOME;
repo_dir=$idir/env_setup;


# structure setup
[ ! -d $idir/bin  ] && mkdir $idir/bin;
[ ! -d $idir/lib  ] && mkdir $idir/lib;
[ ! -d $idir/logs ] && mkdir $idir/logs;


for script_name in $( ls $repo_dir/bin/ )
do
    ln -sf $repo_dir/bin/$script_name $idir/bin/;
done


ln -sf $repo_dir/.bashrc $idir/;
ln -sf $repo_dir/.bash_aliases $idir/;
ln -sf $repo_dir/.bash_logout $idir/;
ln -sf $repo_dir/.vimrc $idir/;
ln -sf $repo_dir/.gitconfig $idir/;
ln -sf $repo_dir/.vim $idir/;

echo "done"

exit 0;




