# linux

### Network

BSD: kqueue, 
Linux 2.4: sigio
Linux 2.6: epoll



##### Default port range
`/proc/sys/net/ipv4/ip_local_port_range`


##### process number
kern.maxproc=100000
/boot/loader.conf
/proc/sys/kernel/pid_max

### execute when boot up
`/etc/rc*` , you can choose /etc/rc.local to write down execution shell code
