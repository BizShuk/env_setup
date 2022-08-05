#!/bin/bash
source settings.sh


# structure setup
setup_structure

for script_name in $( ls $REPO_DIR/bin/ )
do
    ln -sf $REPO_DIR/bin/$script_name $INSTALL_DIR/bin/;
done


### bash ###
ln -sf $REPO_DIR/bash/.bashrc $INSTALL_DIR/;
ln -sf $REPO_DIR/bash/.bash_aliases $INSTALL_DIR/;
ln -sf $REPO_DIR/bash/.bash_function $INSTALL_DIR/;
ln -sf $REPO_DIR/bash/.bash_logout $INSTALL_DIR/;
ln -sf $REPO_DIR/bash/settings.sh $INSTALL_DIR/;
[ ! -e $INSTALL_DIR/.bash_plugin ] && echo  '#!/bin/bash' > $INSTALL_DIR/.bash_plugin;   # for install language


### git ###
ln -sf $REPO_DIR/pkg/git/.gitconfig $INSTALL_DIR/;
ln -sf $REPO_DIR/pkg/git/.gitmessage $INSTALL_DIR/;

### vim ###
ln -sf $REPO_DIR/pkg/vim/.vimrc $INSTALL_DIR/;
ln -sf $REPO_DIR/pkg/vim/.vim $INSTALL_DIR/;

### top ###
ln -sf $REPO_DIR/pkg/top/.toprc $INSTALL_DIR/;

### ssh ###
mkdir $INSTALL_DIR/.ssh
cat $REPO_PKG/sshd/.ssh/id_rsa.pub >> $INSTALL_DIR/.ssh/authorized_keys

### for mac ###
ln -sf $INSTALL_DIR/.bashrc $INSTALL_DIR/.profile


# ln for env_setup to project
if [ ! -d $INSTALL_DIR/env_setup ] || [ ! -d $USER_PROJECT/env_setup ] ; then
    if [ -d $INSTALL_DIR/env_setup ]; then
        ln -sf $INSTALL_DIR/env_setup $USER_PROJECT/env_setup
    else
        ln -sf $USER_PROJECT/env_setup $INSTALL_DIR/env_setup
    fi
fi


echo "Done...... Restart terminal or source ~/.bashrc"




