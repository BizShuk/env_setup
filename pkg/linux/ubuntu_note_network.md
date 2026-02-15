# Network

# This file describes the network interfaces available on your system

# and how to activate them. For more information, see interfaces(5)

# $interface = lo(for 127.0.0.1) , eth0 , eth0:0(同網卡第二個設定) , eth0:1 , eth1 ...etc

# auto $interface

# iface $interface inet [dhcp|static|loopback(for 127.0.0.1)]

# address 192.168.0.89

# network 192.168.0.0 # 此行不寫ok

# netmask 255.255.255.0

# broadcast 192.168.0.255 # 此行不寫ok

# gateway 192.168.0.1 # 通常為.1 除非gateway另外設定

# The loopback network interface

auto lo
iface lo inet loopback

# The primary network interface

# auto eth0

# iface eth0 inet dhcp

auto eth0 eth0:0
iface eth0 inet static
address 192.168.0.150
netmask 255.255.255.0
gateway 192.168.0.1

iface eth0:0 inet static
address 192.168.0.151
netmask 255.255.255.0
gateway 192.168.0.1

### checking ???

- iptables
- nc
- MTU 最大傳輸單位 <http://linux.vbird.org/linux_server/0110network_basic.php#tcpip_link_mtu>
- icmp

### # config definition

- port less than 1024 , used by root only
- /etc/network/interface # 網路設定
  ref. ~/note/files/interface
  and
  `/etc/init.d/networking restart` # restart network ,
  equal `sudo service networking restart`
- /etc/host # mapping ip to host
  ref. ~/note/files/host
  and `/etc/init.d/hostname.sh restart`

- /etc/hostname # for hostname

- DNS client
  `cat /etc/resolv.conf`
- port standard definition
  `/etc/services`

### # basic CMD

##### # ping

ping dns or ip
`ping [ip/domain]

##### # curl

add post data
`curl -d "key=value&key2=value2"  http://domain.com/xxxxx`

read session from file
`curl -b "filename" http://domain.com/xxxxx`

set session to file
`curl -c "filename" http://domain.com/xxxxx`

##### # [netstat](http://blog.gtwang.org/linux/linux-netstat-command-examples/)

- -a , show all socket
- -l , listening port
- -t , show tcp socket
- -u , show udp socket
- -n , show host and port as numbers , instead of resolving in dns and looking in /etc/services
- -c , print every second

- -r , show route table
- -i[e] , show interface , e for detail

還可以統計連線數 ref. to link

##### # nslookup

nslookup $ip
=>

```ini
Server:      10.128.101.1
Address:    10.128.101.1#53

80.80.128.10.in-addr.arpa   name = shuk.dev.droitp.localnet.
```

nslookup $domain
=>

```ini
Server:     10.128.101.1
Address:    10.128.101.1#53

Name:   shuk.dev.droitp.localnet
Address: 10.128.80.80
```

##### # dig

dig -x shuk
; <<>> DiG 9.9.5-3ubuntu0.5-Ubuntu <<>> -x shuk
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 11444
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;shuk.in-addr.arpa. IN PTR

;; AUTHORITY SECTION:
2015072271 1800 900 604800 3600

;; Query time: 36 msec
;; SERVER: 10.128.101.1#53(10.128.101.1)
;; WHEN: Tue Oct 20 09:55:29 CST 2015
;; MSG SIZE rcvd: 114

dig -x 10.128.80.80

;; <<>> DiG 9.9.5-3ubuntu0.5-Ubuntu <<>> -x 10.128.80.80
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 63638
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;80.80.128.10.in-addr.arpa. IN PTR

;; ANSWER SECTION:
80.80.128.10.in-addr.arpa. 3600 IN PTR shuk.dev.droitp.localnet.

;; AUTHORITY SECTION:
80.128.10.in-addr.arpa. 10800 IN NS ns1.dev.droitp.localnet.

;; ADDITIONAL SECTION:
ns1.dev.droitp.localnet. 10800 IN A 10.128.101.1

;; Query time: 0 msec
;; SERVER: 10.128.101.1#53(10.128.101.1)
;; WHEN: Tue Oct 20 09:55:35 CST 2015
;; MSG SIZE rcvd: 126

###### # show network

`ifconfig -a`

##### # traceroute , 連線到目的地的所有封包路徑

`traceroute [ip/domain]`

##### # host , DNS 反查 ip

`host [domain]`

##### # tcpdump , dump traffic

???

##### # iptables

???

###### # ifconfig

`ifconfig -a` , show all network
`ifconfig [ethX] [up/down]` , turn on/off eth card

###### # route

`route -n` , show route table  
`route [add/del] defaut gw xxx.xxx.xxx.xxx` , add/del gateway

##### # [防火牆ufw](http://wiki.ubuntu.org.cn/index.php?title=Ufw%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97&variant=zh-hant)

```sh
sudo ufw enable
sudo ufw disable
sudo ufw allow in http
sudo ufw allow in ssh
```

##### # tcpd wrapper

類似 apache htcaccess裡面的 allow deny
conf:
/etc/hosts.allow
ALL: ALL
/etc/hosts.denys
sshd: ALL

# in.telnetd: 192.168

ALL: 192.168.
ALL: 127.0.0.1

# in.ftpd: ALL

### other packages

##### # arp-scan

# : find local all host in the local network

`sudo arp-scan --localnet  --interface="eth1"`
`arp -a` , show all hosts in subnet

##### # 撥接設定 (ref. <http://note.drx.tw/2008/08/networkpppoe-adsl.html>)

```bash
sudo apt-get install pppoeconf
sudo pppoeconf
```

2.2. 搜尋所有的網路卡 → 是 (yes)。
2.3. 偵測中。
2.4. 確定修改 → 是 (yes)。
2.5. 常用選項 → 是 (yes)。
2.6. 輸入使用者名稱 (以中華電信為例)。

一般使用者：<xxx@hinet.het>
固定 IP 架站者：<xxx@ip.hinet.net> (完成後得再 修改固定 IP)。 (注意 "@" 會因為rpi 鍵盤設定打不出來)
(景美街61號5樓 8546\*\*\*\*)

2.7. 輸入密碼。
2.8. 使用配發 DNS：使用 ISP 提供的 DNS → 是 (yes)。
2.9. 限制 MSS(最大分段大小) 障礙 → 是 (yes)。
2.10. 完成：啟動連線 → 是 (yes)。
2.11. 啟動連線 → 是 (yes)。

PPPoE 撥接成功訊息：
Plugin rp-pppoe.so loaded

3. 基本操作

   3.1. 中斷撥接連線。
   jonny@ubuntu:~$ sudo poff -a

   3.2. 手動撥接。

   3.2.1 切換 root 使用者。
   jonny@ubuntu:~$ sudo su -

   3.2.2 手動撥接。
   root@linux:~$ pon /etc/ppp/peers/dsl-provider

NETWORK settings

```bash
sudo vim /etc/hostname
sudo vim /etc/hosts
sudo /etc/init.d/hostname.sh start
sudo service networking restart


sudo vim /etc/network/interface 改ip
    設定 http://www.cyberciti.biz/faq/setting-up-an-network-interfaces-file/

sudo /etc/init.d/networking start
sudo /etc/init.d/networking stop


curl [-v:show header] [-d "string":push string in request] uri


DHCP

    sudo vim /etc/network/interfaces
            auto eth0
            iface eth0 inet dhcp

    sudo /etc/init.d/networking restart

固定IP

單網卡單 IP
sudo vim /etc/network/interfaces
        auto eth0
        iface eth0 inet static
        address 192.169.1.5
        netmask 255.255.255.0
        gateway 192.168.1.254

sudo /etc/init.d/networking restart

單網卡多個 IP
sudo vim /etc/network/interfaces
        auto eth0:0
        iface eth0:0 inet static
        address 192.169.10.5
        netmask 255.255.255.0
        gateway 192.168.10.254

        auto eth0：1
        iface eth0：1 inet static
        address 192.169.100.5
        netmask 255.255.255.0
        gateway 192.168.100.254

        sudo /etc/init.d/networking restart

    撥接設定
        ref. pppoeconf.settings
```

rinetd 類似proxy
default configuration file : /etc/rinetd.conf
如果要指定conf file , rinetd -c file
不知道為啥沒用預設的conf會沒出現server

### super-daemon

inetd監聽特殊port , sleep the process, 有人發送request才喚醒該process

```bash
/etc/init.d/inetd stop
/etc/init.d/inetd start
```

configuration
`/etc/inetd.conf`

##### openssh

sudo apt-get install openssh-server

2.取消 root 的登入權限

這是基於安全的考量， 一般都不會設定讓 root 可以連進來， 不然，駭客就會很方便的哩 ！ 首先，打開在 /etc/ssh/sshd_config 的 SSH 設定檔，然後，找到下面這一行，把它的 yes 改成 no 之後，就把它存檔起來。

＃PermitRootLogin Yes

或是

PermitRootLogin No

3.設定可以連線的主機

打開 /etc/hosts.allow 檔，把允許的主機 IP 加進來， 以阿舍想要讓 192.168.1.88 這台機器可以連進來為例，就輸入下面這樣的一行,然後就存檔起來。

sshd:192.168.1.88:allow

再來， 再打開 /etc/hosts.deny 檔，把下面這一行給加進去，這樣其它的主機都會被設為拒絕連線，所以，這台主機就只有上面設定的 192.168.1.88 那一台可以連進來了哩。

sshd:all:deny

4.重啟 SSH Server

用下面的指令來重啟 SSH Server 之後，就算安裝設定完成了哩 !

sudo /etc/init.d/ssh restart

另外，如果要使用更安全的以憑證來連線 SSH ，就請參考這裡。

Read more: <http://www.arthurtoday.com/2010/08/ubuntu-ssh.html#ixzz3kkegruwM>
