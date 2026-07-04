#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/settings.sh"

if command -v python3-config &>/dev/null; then
    python_config_dir=$(python3-config --configdir)
elif command -v python-config &>/dev/null; then
    python_config_dir=$(python-config --configdir)
else
    python_config_dir=$(python3 -c "import sysconfig; print(sysconfig.get_config_var('LIBPL'))" 2>/dev/null)
fi

if [ "${OS}" = "darwin" ]; then
    PREFIX="${USER_LOCAL}"
    MAKE_INSTALL_CMD="make install"
    if command -v brew &>/dev/null; then
        BREW_PREFIX=$(brew --prefix)
        export LDFLAGS="-L${BREW_PREFIX}/lib ${LDFLAGS:-}"
        export CFLAGS="-I${BREW_PREFIX}/include ${CFLAGS:-}"
        export CPPFLAGS="-I${BREW_PREFIX}/include ${CPPFLAGS:-}"
    fi
else
    sudo apt-get install -y ncurses-dev # terminal library
    PREFIX="/usr"
    MAKE_INSTALL_CMD="sudo make install"
fi

VIM_VER="v9.2.0750"

tmpdir=$(mktemp -d)

pushd "$tmpdir" || exit
curl -LO https://github.com/vim/vim/archive/${VIM_VER}.tar.gz
tar zxf ${VIM_VER}.tar.gz
cd vim-${VIM_VER:1} || exit
./configure --enable-python3interp \
    --with-python3-config-dir="${python_config_dir}" \
    --enable-perlinterp \
    --with-features=huge \
    --enable-cscope \
    --prefix="${PREFIX}"
make
${MAKE_INSTALL_CMD}
rm -rf "vim-${VIM_VER:1}" && rm -f "${VIM_VER}.tar.gz"
popd || exit
rm -rf "$tmpdir"

# for ctag
. "$(dirname "$0")/ctags_setup.sh"

git submodule init
git submodule update

echo "check :py3 print(\"yes\") and edit tmp.c with for snippets"
