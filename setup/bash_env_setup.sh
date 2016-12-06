#!/bin/bash
source settings.sh


# structure setup
setup_structure

for script_name in $( ls $sdir/bin/ )
do
    ln -sf $sdir/bin/$script_name $idir/bin/;
done


### bash ###
ln -sf $sdir/bash/.bashrc $idir/;
ln -sf $sdir/bash/.bash_aliases $idir/;
ln -sf $sdir/bash/.bash_function $idir/;
ln -sf $sdir/bash/.bash_logout $idir/;
ln -sf $sdir/bash/settings.sh $idir/;
[ ! -e $idir/.bash_plugin ] && echo  '#!/bin/bash' > $idir/.bash_plugin;   # for install language


### git ###
ln -sf $sdir/pkg/git/.gitconfig $idir/;

### vim ###
ln -sf $sdir/pkg/vim/.vimrc $idir/;
ln -sf $sdir/pkg/vim/.vim $idir/;

### top ###
ln -sf $sdir/pkg/top/.toprc $idir/;

### ssh ###
mkdir $idir/.ssh
cat $pkg_sdir/sshd/.ssh/id_rsa.pub >> $idir/.ssh/authorized_keys

### for mac ###
ln -sf $idir/.bashrc $idir/.profile


# ln for env_setup to project
if [ ! -d $idir/env_setup ] || [ ! -d $idir/project/env_setup ] ; then
    if [ -d $idir/env_setup ]; then
        ln -sf $idir/env_setup $idir/project/env_setup
    else
        ln -sf $idir/project/env_setup $idir/env_setup
    fi
fi

### server project ###
mkdir $idir/server/server_status        # general static server status 
ln -sf $idir/project/bizshuk.github.io  $idir/server/
ln -sf $idir/project/test               $idir/server/
ln -sf $idir/project/slURL              $idir/server/
ln -sf $idir/project/VideoChannel       $idir/server/
ln -sf $idir/project/static             $idir/server/
ln -sf $idir/project/stat               $idir/server/
ln -sf $idir/project/podcastWeb         $idir/server/
ln -sf $idir/project/MissOld            $idir/server/
ln -sf $idir/project/Gifting            $idir/server/
ln -sf $idir/project/FascinatingMap     $idir/server/
ln -sf $idir/project/elfVision          $idir/server/
ln -sf $idir/project/treeMonitor        $idir/server/
ln -sf $idir/project/treeMonitor        $idir/server/



echo "Done...... Restart terminal or source ~/.bashrc"




