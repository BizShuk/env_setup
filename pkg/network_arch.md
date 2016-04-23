x for subnet

### for all
x.1~x.20 , x.254 , x.255 reserved
dhcp range: 100 ~ 240
dns: x.9
gateway: x.254



### public
use class C: 192.168.10.0
samba       x.10
printer     x.11


### dev
use class b: 172.20.0.0

connect with: public , deploy


### deploy
use class a: 10.0.0.0
reponsible for docker images, basic check





