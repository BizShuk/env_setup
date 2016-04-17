#!/bin/bash
source settings.sh

setup_structure



echo "# Golang" >> $idir/.bash_plugin
echo "append GOPATH to $idir/.bash_plugin"
echo "export GOPATH=$go_path" >> $idir/.bash_plugin  && mkdir $project_dir/go_project 2>/dev/null
echo "export gopath=$go_path" >> $idir/.bash_plugin
echo 'export PATH=$PATH:$GOPATH/bin' >> $idir/.bash_plugin




[ -e $lib_dir/$go_fullversion ] && echo "$go_fullversion has already installed" && exit 0
[ -e $bin_dir/go ]          && echo "go has already installed , now install $go_fullversion"

wget https://storage.googleapis.com/golang/${go_fullversion}.tar.gz -O /tmp/$go_fullversion
echo "untar $go_fullversion ..."
tar zxf /tmp/$go_fullversion -C /tmp 
mv /tmp/go $lib_dir/$go_fullversion
ln -sf $lib_dir/$go_fullversion $bin_dir/go

echo "export GOROOT=${go_root}" >> $idir/.bash_plugin
echo "export goroot=${go_root}" >> $idir/.bash_plugin
echo "export PATH=\$PATH:$GOROOT/bin" >> $idir/.bash_plugin

source ~/.bashrc 
go get -u github.com/jstemmer/gotags

echo ""
echo "##########"
echo "please remove go env path in $idir/.bsah_plugin if you have go before"
echo "or you want to use other installed version , please add path to \$PATH"
echo "##########"
