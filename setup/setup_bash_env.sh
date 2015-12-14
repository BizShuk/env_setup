#!/bin/bash
source settings.sh


# structure setup
setup_structure

for script_name in $( ls $sdir/bin/ )
do
    ln -sf $sdir/bin/$script_name $idir/bin/;
done


# bash
ln -sf $sdir/bash/.bashrc $idir/;
ln -sf $sdir/bash/.bash_aliases $idir/;
ln -sf $sdir/bash/.bash_function $idir/;
ln -sf $sdir/bash/.bash_logout $idir/;
ln -sf $sdir/bash/settings.sh $idir/;
[ ! -e $idir/.bash_plugin ] && echo  '' > $idir/.bash_plugin;   # for install language

# git
ln -sf $sdir/git/.gitconfig $idir/;

# vim
ln -sf $sdir/vim/.vimrc $idir/;
ln -sf $sdir/vim/.vim $idir/;



echo "done...... please restart terminal"

exit 0;




