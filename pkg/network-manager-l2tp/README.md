# Network-manager-l2tp


in building process , there are a lot of dependancies. Just apt-get install , and check error/ubuntu_build.md as refereneces.

### related package
- xl2tpd
- ipsec

1. `git clone https://github.com/nm-l2tp/network-manager-l2tp`
2. `./autogen.sh`
3.  
```bash
./configure \
    --prefix=/usr --localstatedir=/var --sysconfdir=/etc \
    --libexecdir=/usr/lib/NetworkManager \
    --with-pppd-plugin-dir=/usr/lib/pppd/2.4.7 \
    --enable-absolute-paths
```
4. `make`
5. `sudo make install`

when use l2tp , it should disable xl2tpd. Because they use the same port 1701.


### debug
```
sudo killall -TERM nm-l2tp-service
sudo /usr/lib/NetworkManager/nm-l2tp-service --debug
```


### may related
- strongswan
- netowrk-manager-strongswan
- libreswan
