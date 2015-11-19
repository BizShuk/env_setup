## note

!! , execute laster command




Ref: 
- [Master Your Unix Shell Env](http://www.cyberciti.biz/howto/shell-primer-configuring-your-linux-unix-osx-environment/)



undoc:
- netstat [#12](http://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html)
- iptablr [#14](http://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html)
- firewall [#14](http://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html)
- baskup stuff [#22](http://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html)
- debug web server [#15](http://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html)





## Memcached ##
alias mcdstats='/usr/bin/memcached-tool 10.10.29.68:11211 stats'
alias mcdshow='/usr/bin/memcached-tool 10.10.29.68:11211 display'
alias mcdflush='echo "flush_all" | nc 10.10.29.68 11211'

