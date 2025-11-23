# Bash

### Ref: 
- [Master Your Unix Shell Env](http://www.cyberciti.biz/howto/shell-primer-configuring-your-linux-unix-osx-environment/)
- [nixCraft](http://www.cyberciti.biz/nixcraft-rss-feed-syndication/)
- [15 Useful Linux and Unix Tape Managements Commands For Sysadmins](http://www.cyberciti.biz/hardware/unix-linux-basic-tape-management-commands/)
- [20 Unix Command Line Tricks ¨C Part I](http://www.cyberciti.biz/open-source/command-line-hacks/20-unix-command-line-tricks-part-i/)
- [bash hotkey](http://ss64.com/bash/syntax-keyboard.html)


### env
PATH



### variable meaning
- `$?` , last command status
- `$0` , shell name
- `$#` , parameter's count
- `$*` , no diff with $@ , but "$@" => "" for each one parameter
- `$@` , no diff with $* , but "$*" => "" for all parameter together
- `$!` , last job id
- `$$` , current shell id
- `$_` , last argument in last command
- `!!` , execute last command 
- `!$` , last command's parameters
- `!servive` , run last command beginning with "service" 
- `ctrl+z + [fg|bg]` , make process to background or foreground
- `--` , end of options
- `$FUNCNAME` , function name

### variable operation
http://www.thegeekstuff.com/2010/07/bash-string-manipulation/?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+TheGeekStuff+(The+Geek+Stuff)

subsititution:  
- `${var:start:length}` , get substring  
- `${var//search/substitude}` , replace substring  
  
default value:  
- `${var:=value}` , output: default , "$var" == "<value>"  
- `${var:-value}` 如果var有值了那麼就用原本的值，不然用value的值
- `${var:+value}` 如果var有值就用value的值
- `${var:?message}` var有值那麼就用原本的值，不然就印出message 值到螢幕並且跳出。

get sub string:  
- `${var:%pattern}` 如果pattern與var後面的部份吻合，傳回剩下沒有 吻合部份給var
- `${var:#pattern}` 如果pattern與var前面的部份吻合，傳回剩下沒有 吻合部份給var


array:
```bash
tmp=(1 2 3 3 4 5)
echo ${tmp[0]}
echo ${tmp[1]}
echo ${tmp[2]}
echo ${tmp[3]}
```




### io direction
- `command > <file>` redirect to file
- `> <file>` , truncate file to 0 length
- `>> <file>` , append to file
- `1> <file>` , stdout to file
- `2> <file>` , stderr to file
- `&> <file>` , both stdout and stderr to file
- `2>&1` , redirect stderr to stdout
- `< <file>` , accept input from a file
- `<<< $var` , accept input from variable

##### Deal with big file
- Edit with `less` or `cat <file> | less`  
- Delete a HUGE file  
    1. `> /path/to/file.log`
    2. `rm /path/to/file.log`


### file desciptor (fd)
A temporary redirect operation.  
syntax:`<src_fd>[<>]&[<fd>-]`  

- `<fd><&-` , close input fd
- `<fd>>&-` , close output fd
- `>&<fd>` , redirect to <fd>



### Calculation
`answer=$(( $x - $y))`


### getopts
getopts <opt_pattern> <opt_var>

no two arguments for one option , recommanded `-r "arg1 arg2 arg3"`

$OPTIND
$OPTARG
$OPTERR

special $opt meaning 
\? , non-expected option
: , expect a argument for option but not found

opt pattern
preding with : , turn getopts to silent error reporting mode , will not show disturbing message

usage
```
while getopts ":s:" opt ; do
    case $opt in 
        s)
            echo 123
            ;;
        \?)
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            ;;
    esac
done
```

another without getopts
```
while shift; do
    case $1 in
        a) ;;
        b) ;;
        c) ;;
    esac
done

```



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












