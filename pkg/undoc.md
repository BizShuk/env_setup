undoc

wget --no-check-certificate https://cyberciti.biz/foo/bar.tar.gz


sudo cp /usr/share/zoneinfo/Aisa/Taipei /etc/localtime
更換時區檔

nginx

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8



#!/bin/bash
source settings.sh
echo "export GOROOT=/home/shuk/lib/golang" >> $HOME/.bashrc
echo "export GOPATH=/home/shuk/lib/go_lib" >> $HOME/.bashrc
echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin' >> $HOME/.bashrc
source $HOME/.bashrc


    tail -n +1 => start from line 1
for ignore first line , tail -n +2


http://dominic16y.world.edoors.com/Cuf9UVglg1a0

* 直接編輯 /etc/init.d/rcS ，放在最後面
* 編寫script檔後，放到 /etc/init.d目錄下
* 使用update-rc.d 指令


nslookup [ domain | ip ]




dig [-x|+trace|-t type]
- -x 反查ip ex: dig -x 8.8.8.8
- +trace 
- -t type



### in future

nginx 拆封包 乘載大量量

### network


ifocnfig    # 目前啟動的
ifconfig -a # 含沒有啟動


ifup eth1

### ???
lspci


ip addr show



### bridege

brctl addbr br0 # create bridge 0


auto br0
iface br0 inet dhcp
bridge_ports eth1
bridge_Stp off
bridge_waitport 0
bridge_fd 0


ifconfig br0 up
ifconfig eht1 down



modify /etc/default/docker
    DOCKER_OPTS="-b=$bridge_name"

sudo service docker restart
