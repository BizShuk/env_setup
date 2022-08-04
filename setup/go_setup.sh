#!/bin/bash
source settings.sh

setup_structure

# Go env
GO_VER=${GO_VER:-1.18.4}
GO_ARCH=""
case "${cpu_arch}" in
    i386)
        GO_ARCH="386"
    ;;
    armv6l)
        GO_ARCH=${cpu_arch}
    ;;
    *)
        GO_ARCH="amd64" # x86_64
    ;;
esac

go_fullversion="go${GO_VER}.${os}-${GO_ARCH}"
GO_ROOT="$USER_LIB/$go_fullversion"  # go package dir
GO_PATH="$INSTALL_DIR/proejct/go_project"   # Where the go dependency/library downloaded


[ -e $USER_LIB/$go_fullversion ] && echo "$go_fullversion has already installed" && exit 0
[ -e $USER_BIN/go ]          && echo "go has already installed , now install $go_fullversion"

wget https://storage.googleapis.com/golang/${go_fullversion}.tar.gz -O /tmp/$go_fullversion
echo "untar $go_fullversion ..."
tar zxf /tmp/$go_fullversion -C /tmp
mv /tmp/go $USER_LIB/$go_fullversion
ln -sf $USER_LIB/$go_fullversion $USER_BIN/go

echo "export GOROOT=${GO_ROOT}" >> $INSTALL_DIR/.bash_plugin
echo "export goroot=${GO_ROOT}" >> $INSTALL_DIR/.bash_plugin
echo "export PATH=\$GOROOT/bin:\$GOPATH/bin:\$PATH" >> $INSTALL_DIR/.bash_plugin
echo "# GOVCS control which version control tool is used for go get from 1.16"
echo "export GOVCS=git"
source ~/.bashrc
go get -u github.com/jstemmer/gotags

echo ""
echo "##########"
echo "please remove go env path in $INSTALL_DIR/.bsah_plugin if you have go before"
echo "or you want to use other installed version , please add path to \$PATH"
echo "##########"
