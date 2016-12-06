#!/bin/bash


.  settings.sh

setup_structure


echo $project_dir
pushd "$project_dir"
    [ ! -d "$project_dir/bizshuk.github.io" ] && git clone https://github.com/bizshuk/bizshuk.github.io 
    [ ! -d "$project_dir/static" ] && git cloe https://github.com/bizshuk/static
    [ ! -d "$project_dir/code_sandbox" ] && git clone https://github.com/bizshuk/code_sandbox 
    [ ! -d "$project_dir/code_alog" ] && git clone https://github.com/bizshuk/code_algo
    [ ! -d "$project_dir/code_concept" ] && git clone https://github.com/bizshuk/code_concept
    [ ! -d "$project_dir/slURL" ] && git clone https://github.com/bizshuk/slURL
    [ ! -d "$project_dir/test" ] && git clone https://github.com/bizshuk/test
    [ ! -d "$project_dir/videochannel" ] && git clone https://github.com/bizshuk/videochannel

popd


pushd "$idir/server"
    ln -sf $idir/project/bizshuk.github.io $idir/server/ 
    ln -sf $idir/project/static $idir/server/ 
    ln -sf $idir/project/test $idir/server/ 
    ln -sf $idir/project/slURL $idir/server/ 
    ln -sf $idir/project/videochannel $idir/server/ 
popd

hosts="
127.0.1.1   t.shuk.info                                                       
127.0.1.1   test.t.shuk.info
127.0.1.1   videochannel.t.shuk.info
127.0.1.1   slurl.t.shuk.info
127.0.1.1   l.t.shuk.info
127.0.1.1   staitc.t.shuk.info
"
ori_hosts="`cat /etc/hosts`"

if [ -e /etc/hosts.bak ]; then
    ori_hosts="`cat /etc/hosts.bak`"
else
    sudo cp /etc/hosts /etc/hosts.bak
fi

new_hosts="$ori_hosts$hosts"
sudo -- bash -c "echo '$new_hosts' > /etc/hosts"


