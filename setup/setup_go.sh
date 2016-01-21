#!/bin/bash
source settings.sh

setup_structure


[ -e $lib_dir/$go_version ] && echo "$go_version has already installed" && exit 0
[ -e $bin_dir/go ]          && echo "go has already installed , now install $go_version"

wget https://storage.googleapis.com/golang/${go_version}.tar.gz -O /tmp/$go_version

echo "untar $go_version ..."
tar zxf /tmp/$go_version -C /tmp 
mv /tmp/go $lib_dir/$go_version
ln -sf $lib_dir/$go_version $bin_dir/go



echo ""
echo "append env variable to $idir/.bash_plugin"
echo "export GOROOT=$go_root" >> $idir/.bash_plugin && mkdir $bin_dir > /dev/null
echo 'export PATH=$PATH:$GOROOT/bin' >> $idir/.bash_plugin
echo "export GOPATH=$go_path" >> $idir/.bash_plugin  && mkdir $project_dir/go_project



echo ""
echo "##########"
echo "please remove go env path in $idir/.bsah_plugin if you have go before"
echo "or you want to use other installed version , please ln -sf <go_package> $bin_dir/go"
echo "##########"
