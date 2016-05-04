## bash

### Ref: 
- [Master Your Unix Shell Env](http://www.cyberciti.biz/howto/shell-primer-configuring-your-linux-unix-osx-environment/)
- [nixCraft](http://www.cyberciti.biz/nixcraft-rss-feed-syndication/)
- [15 Useful Linux and Unix Tape Managements Commands For Sysadmins](http://www.cyberciti.biz/hardware/unix-linux-basic-tape-management-commands/)
- [20 Unix Command Line Tricks ¨C Part I](http://www.cyberciti.biz/open-source/command-line-hacks/20-unix-command-line-tricks-part-i/)

### special not
- `!!` , execute last command 
- `!$` , last command's parameters
- `!servive` , run last command beginning with "service" 
- `ctrl+z + [fg|bg]` , make process to background or foreground


### Deal with big file

- Edit with `less` or `cat <file> | less`  
- Delete a HUGE file  
    1. `> /path/to/file.log`
    2. `rm /path/to/file.log`

### variable note

### cmd usage note
cmd_usage.md


### undoc:
- how to customize `ps` , `netstat` , `route` , `top` ( in bash_aliases)
ethtool ifac
cat /var/log/syslog
nslookup
cat /etc/resolv.conf
netstat -rn
dhclient iface

- netstat [#12](http://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html)
- iptablr [#14](http://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html)
- firewall [#14](http://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html)
- baskup stuff [#22](http://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html)
- debug web server [#15](http://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html)

- ifdata
- pv
- cracklib-*
- [Top 20 OpenSSH Server Best Security Practices](http://www.cyberciti.biz/tips/linux-unix-bsd-openssh-server-best-practices.html)


## Memcached ##
alias mcdstats='/usr/bin/memcached-tool 10.10.29.68:11211 stats'
alias mcdshow='/usr/bin/memcached-tool 10.10.29.68:11211 display'
alias mcdflush='echo "flush_all" | nc 10.10.29.68 11211'



