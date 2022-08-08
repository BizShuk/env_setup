#!/bin/bash

source settings.sh

tmpdir=`mktemp -d`

which python-config
if [ "$?" != "0" ]; then
    echo python config dir is not existed
    exit 1
fi


python_config_dir=`python-config --ldflags |awk '{print $1}'`
python_config_dir=${python_config_dir:2}

sudo apt-get install -y ncurses-dev # terminal library

VIM_VER="v7.4.1692"
pushd "$tmpdir"
    wget https://github.com/vim/vim/archive/v7.4.1692.tar.gz
    tar zxf ${VIM_VER}.tar.gz
    cd vim-${VIM_VER:1}
    ./configure --enable-pythoninterp \
        --with-python-config-dir=${python_config_dir} \
        --enable-perlinterp \
        --with-features=huge \
        --enable-cscope \
        --prefix=/usr
    make
    sudo make install
    rm -r ${VIM_VER} && rm ${VIM_VER}.tar.gz
popd
# --enable-python3interp
# --with-python3-config-dir



# for ctag
. ./ctags_setup.sh

git submodule init
git submodule update

echo check :py print("yes") and edit tmp.c with for snippets
#echo check :py3 print("yes") and edit tmp.c with for snippets

