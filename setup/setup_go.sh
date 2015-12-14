#!/bin/bash
source ./settings.sh

setup_structure

wget https://storage.googleapis.com/golang/$go_version -O /tmp/$go_version
tar zxvf /tmp/$go_version -C $bin_dir
rm /tmp/$go_version





echo "export GOROOT=$go_root" >> $idir/.bash_plugin
echo 'export PATH=$PATH:$GOROOT/bin' >> $idir/.bash_plugin
echo "export GOPATH=$go_path" >> $idir/.bash_plugin
