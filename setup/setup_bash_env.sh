#!/bin/bash
source settings.sh


# structure setup
[ ! -d $idir/bin  ] && mkdir $idir/bin;
[ ! -d $idir/lib  ] && mkdir $idir/lib;
[ ! -d $idir/logs ] && mkdir $idir/logs;


for script_name in $( ls $sdir/bin/ )
do
    ln -sf $sdir/bin/$script_name $idir/bin/;
done


ln -sf $sdir/.bashrc $idir/;
[ "$os" == "Darwin" ] && ln -sf $idir/.bashrc $idir/.profile;
ln -sf $sdir/.bash_aliases $idir/;
ln -sf $sdir/.bash_logout $idir/;
ln -sf $sdir/.vimrc $idir/;
ln -sf $sdir/.gitconfig $idir/;
ln -sf $sdir/.vim $idir/;



echo "done"

exit 0;




