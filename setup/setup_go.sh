#!/bin/bash
source ./settings.sh

setup_structure


[ -e $bin_dir/$go_version ] && echo "$go_version has already installed" && exit 0
[ -e $bin_dir/go ]          && echo "go has already installed , now install $go_version"

wget https://storage.googleapis.com/golang/${go_version}.tar.gz -O /tmp/$go_version
tar zxf /tmp/$go_version -C /tmp 
mv /tmp/go $bin_dir/$go_version
ln -sf $bin_dir/$go_version $bin_dir/go





echo "export GOROOT=$go_root" >> $idir/.bash_plugin
echo 'export PATH=$PATH:$GOROOT/bin' >> $idir/.bash_plugin
echo "export GOPATH=$go_path" >> $idir/.bash_plugin
