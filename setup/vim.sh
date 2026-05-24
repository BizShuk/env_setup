#!/bin/bash

source "$(dirname "$0")/settings.sh"

if command -v python3-config &>/dev/null; then
    python_config_dir=$(python3-config --configdir)
elif command -v python-config &>/dev/null; then
    python_config_dir=$(python-config --configdir)
else
    python_config_dir=$(python3 -c "import sysconfig; print(sysconfig.get_config_var('LIBPL'))" 2>/dev/null)
fi

sudo apt-get install -y ncurses-dev # terminal library

VIM_VER="v9.1.0"

tmpdir=$(mktemp -d)

pushd "$tmpdir" || exit
wget https://github.com/vim/vim/archive/${VIM_VER}.tar.gz
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
rm -rf "vim-${VIM_VER:1}" && rm -f "${VIM_VER}.tar.gz"
popd || exit
# --enable-python3interp
# --with-python3-config-dir

# for ctag
. ./ctags_setup.sh

git submodule init
git submodule update

echo "check :py print("yes") and edit tmp.c with for snippets"
#echo "check :py3 print("yes") and edit tmp.c with for snippets"
