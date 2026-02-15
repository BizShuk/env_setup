# Engineer Note

## IPVS , IP virtual server

[Wiki](http://kb.linuxvirtualserver.org/wiki/Main_Page)

## linux kernel structure

## linux

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

## ulimit

- `ulimit -a` , show all
- `ulimit -n 65536` , increasing open files
