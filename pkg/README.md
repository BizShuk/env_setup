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

## top

Need to Know:

- k , kill process
- r , renice process
- < or > , move sorted column
- L , find
- c , show full cmd path
- H , switch Thread and Task

Know but not important:

- f , select fields to show and sort
- E , change unit for mem and cpu
- W , write configure to .toprc
- q , quit
- h , help

Theme:

- Z , for color setting with 4 modes
- J , align right or left
- x , hightlight sort field
- y, hightlight running process

Process:

- V , with process Heichyrachy
- 1 , show all cpu or total
- 2 , show node view
- 0 , hide %CPU under 0.1%
- I , Irix mode ????
