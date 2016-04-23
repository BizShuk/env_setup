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
[ ! -e $idir/.bash_plugin ] && echo  '#!/bin/bash' > $idir/.bash_plugin;   # for install language

ln -sf /var/log/samba $idir/log/samba


# git
ln -sf $sdir/git/.gitconfig $idir/;

# vim
ln -sf $sdir/vim/.vimrc $idir/;
ln -sf $sdir/vim/.vim $idir/;

# for mac
ln -sf $idir/.bashrc $idir/.profile


# ln for env_setup to project
ln -sf $idir/env_setup $idir/project/env_setup

echo "Done...... Restart terminal"




