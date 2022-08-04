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
GO_ROOT="$lib_dir/$go_fullversion"  # go package dir
GO_PATH="$project_dir/go_project"   # Where the go dependency/library downloaded


[ -e $lib_dir/$go_fullversion ] && echo "$go_fullversion has already installed" && exit 0
[ -e $bin_dir/go ]          && echo "go has already installed , now install $go_fullversion"

wget https://storage.googleapis.com/golang/${go_fullversion}.tar.gz -O /tmp/$go_fullversion
echo "untar $go_fullversion ..."
tar zxf /tmp/$go_fullversion -C /tmp
mv /tmp/go $lib_dir/$go_fullversion
ln -sf $lib_dir/$go_fullversion $bin_dir/go

echo "export GOROOT=${GO_ROOT}" >> $idir/.bash_plugin
echo "export goroot=${GO_ROOT}" >> $idir/.bash_plugin
echo "export PATH=\$GOROOT/bin:\$GOPATH/bin:\$PATH" >> $idir/.bash_plugin
echo "# GOVCS control which version control tool is used for go get from 1.16"
echo "export GOVCS=git"
source ~/.bashrc
go get -u github.com/jstemmer/gotags

echo ""
echo "##########"
echo "please remove go env path in $idir/.bsah_plugin if you have go before"
echo "or you want to use other installed version , please add path to \$PATH"
echo "##########"
