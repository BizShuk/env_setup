#!/bin/bash
source settings.sh

setup_structure

# Go env
GO_ARCH=""
case "${CPU_ARCH}" in
i386)
    GO_ARCH="386"
    ;;
arm64)
    GO_ARCH=${CPU_ARCH}
    ;;
*)
    GO_ARCH="amd64" # x86_64
    ;;
esac

GO_VER=${GO_VER:-1.21.1}
GO_FULLVER="go${GO_VER}.${os}-${GO_ARCH}"
GO_ROOT="$USER_LIB/$GO_FULLVER"    # go package dir
GO_PATH="$USER_PROJECT/go_project" # Where the go dependency/library downloaded

[ -e $USER_LIB/$GO_FULLVER ] && echo "$GO_FULLVER has already installed" && exit 0
[ -L $USER_BIN/go ] && echo "go has already installed , now install $GO_FULLVER"

wget https://storage.googleapis.com/golang/${GO_FULLVER}.tar.gz -O /tmp/$GO_FULLVER

tar zxf /tmp/$GO_FULLVER -C /tmp
mv /tmp/go $USER_LIB/$GO_FULLVER

echo -e "\n# [Go]" >>${INSTALL_DIR}/.bash_plugin
echo "export GOROOT=${GO_ROOT}" >>${INSTALL_DIR}/.bash_plugin
echo "export goroot=${GO_ROOT}" >>${INSTALL_DIR}/.bash_plugin
echo "export GOPATH=${GO_PATH}" >>${INSTALL_DIR}/.bash_plugin
echo "export PATH=\$GOROOT/bin:\$GOPATH/bin:\$PATH" >>${INSTALL_DIR}/.bash_plugin

echo "# [GOVCS] control which version control tool is used for go get from 1.16" >>${INSTALL_DIR}/.bash_plugin
echo "export GOVCS=git" >>${INSTALL_DIR}/.bash_plugin

# source ~/.bashrc
# go get -u github.com/jstemmer/gotags
# echo ""
# echo "##########"
# echo "please remove go env path in $INSTALL_DIR/.bsah_plugin if you have go before"
# echo "or you want to use other installed version , please add path to \$PATH"
# echo "##########"
