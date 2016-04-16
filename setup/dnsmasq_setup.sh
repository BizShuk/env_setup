#!/bin/bash

source settings.sh


tmp_dir=`mktemp -d`

dnsmasq_ver=2.75
dnsmasq_name="dnsmasq-${dnsmasq_ver}"

pushd $tmp_dir
    wget http://www.thekelleys.org.uk/dnsmasq/${dnsmasq_name}.tar.gz
    tar zxvf ${dnsmasq_name}.tar.gz
    cd ${dnsmasq_name}
    sudo make install
popd

rm -rf $tmp_dir


echo sample config file under "server_config/dnsmasq.conf"
echo ref:https://github.com/bizshuk/tech/dns.md
