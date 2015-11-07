#!/bin/bash
source settings.sh


# structure setup
[ ! -d $idir/bin  ] && mkdir $idir/bin;
[ ! -d $idir/lib  ] && mkdir $idir/lib;
[ ! -d $idir/logs ] && mkdir $idir/logs;
[ ! -d $idir/projects ] && mkdir $idir/projects;


for script_name in $( ls $sdir/bin/ )
do
    ln -sf $sdir/bin/$script_name $idir/bin/;
done


# bash
ln -sf $sdir/bash/.bashrc $idir/;
ln -sf $sdir/bash/.bash_aliases $idir/;
ln -sf $sdir/bash/.bash_logout $idir/;

# git
ln -sf $sdir/git/.gitconfig $idir/;

# vim
ln -sf $sdir/vim/.vimrc $idir/;
ln -sf $sdir/vim/.vim $idir/;



echo "done"

exit 0;




