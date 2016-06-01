#!/bin/bash


.  settings.sh

setup_structure


echo $project_dir
pushd "$project_dir"
    [ ! -d "$project_dir/bizshuk.github.io" ] && git clone https://github.com/bizshuk/bizshuk.github.io 
    [ ! -d "$project_dir/static" ] && git cloe https://github.com/bizshuk/static
    [ ! -d "$project_dir/code_sandbox" ] && git clone https://github.com/bizshuk/code_sandbox 
popd


pushd "$idir/server"
    ln -sf $idir/project/bizshuk.github.io $idir/server/ 
    ln -sf $idir/project/static $idir/server/ 
popd

hosts="
127.0.1.1   shuk.info.t                                                         
127.0.1.1   biz.shuk.info.t
127.0.1.1   code_sandbox.shuk.info.t
"
ori_hosts="`cat /etc/hosts`"

if [ -e /etc/hosts.bak ]; then
    ori_hosts="`cat /etc/hosts.bak`"
else
    sudo cp /etc/hosts /etc/hosts.bak
fi

new_hosts="$ori_hosts$hosts"
sudo -- bash -c "echo '$new_hosts' > /etc/hosts"


