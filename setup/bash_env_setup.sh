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
ln -sf $sdir/pkg/git/.gitconfig $idir/;

# vim
ln -sf $sdir/pkg/vim/.vimrc $idir/;
ln -sf $sdir/pkg/vim/.vim $idir/;

# top
ln -sf $sdir/pkg/top/.toprc $idir/;

# ssh
ln -sf $sdir/pkg/sshd/.ssh $idir/

# for mac
ln -sf $idir/.bashrc $idir/.profile


# ln for env_setup to project
if [ ! -d $idir/env_setup ] || [ ! -d $idir/project/env_setup ] ; then
    if [ -d $idir/env_setup ]; then
        ln -sf $idir/env_setup $idir/project/env_setup
    else
        ln -sf $idir/project/env_setup $idir/env_setup
    fi
fi

echo "Done...... Restart terminal"




