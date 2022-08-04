#!/bin/bash
source settings.sh

setup_structure

[ -e $lib_dir/$go_fullversion ] && echo "$go_fullversion has already installed" && exit 0
[ -e $bin_dir/go ]          && echo "go has already installed , now install $go_fullversion"

wget https://storage.googleapis.com/golang/${go_fullversion}.tar.gz -O /tmp/$go_fullversion
echo "untar $go_fullversion ..."
tar zxf /tmp/$go_fullversion -C /tmp 
mv /tmp/go $lib_dir/$go_fullversion
ln -sf $lib_dir/$go_fullversion $bin_dir/go

echo "export GOROOT=${go_root}" >> $idir/.bash_plugin
echo "export goroot=${go_root}" >> $idir/.bash_plugin
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
