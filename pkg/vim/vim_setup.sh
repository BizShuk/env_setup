#!/bin/bash

source settings.sh
source ~/project/ubuntu_setup/alias/python-config.sh

python_config_dir=$(get_python-config-dir)

sudo apt-get install -y ncurses-dev # terminal library

VIM_VER="v7.4.1692"

tmpdir=$(mktemp -d)

pushd "$tmpdir" || exit
wget https://github.com/vim/vim/archive/v7.4.1692.tar.gz
tar zxf ${VIM_VER}.tar.gz
cd vim-${VIM_VER:1} || exit
./configure --enable-pythoninterp \
    --with-python-config-dir="${python_config_dir}" \
    --enable-perlinterp \
    --with-features=huge \
    --enable-cscope \
    --prefix=/usr
make
sudo make install
rm -r ${VIM_VER} && rm ${VIM_VER}.tar.gz
popd || exit
# --enable-python3interp
# --with-python3-config-dir

# for ctag
. ./ctags_setup.sh

git submodule init
git submodule update

echo "check :py print("yes") and edit tmp.c with for snippets"
#echo "check :py3 print("yes") and edit tmp.c with for snippets"
