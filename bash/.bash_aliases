#!/bin/bash

## env ##
os="$(uname)"


## alias cmd ##
#ref: [30 Handy Bash Shell Aliases](http://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html)





## system operator ##
alias update='sudo apt-get update && sudo apt-get upgrade'
alias shutdown_reboot='sudo /sbin/reboot'
alias shutdown_poweroff='sudo /sbin/poweroff'
alias shutdown_halt='sudo /sbin/halt'
alias shutdown='sudo /sbin/shutdown'

alias p="ps axu"        # show process list
alias t="top"           # show top process using most resources
alias h='history'
alias j='jobs -l'




## New CMDs ##
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowtime=now
alias nowdate='date +"%d-%m-%Y"'

#size of disks , dirs , and files
#   -h , for human readable
#   -s , for summary
#
alias disk_size="df -h"
alias file_size="du -sh *"  
alias dir_size="du -sh"



## Add default option for CMDs ##

#alias dir='dir --color=auto'        # = ls  
#alias vdir='vdir --color=auto'      # = ls -l 
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias vi='vim'
alias edit='vim'
alias ping='ping -c 5'              # Stop after sending count ECHO_REQUEST packets 
alias pingfast='ping -c 100 -s.2'   # Do not wait interval 1 second, go fast 

# don't change /'s owner group and mod
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'


# confirmation #
#alias mv='mv -i'
#alias cp='cp -i'
#alias ln='ln -i'

 

## ls ##
#   -F = --file-type , show different with file type
#   -G = --color=auto , with color
if [ "$os" == "Darwin" ]; then
    alias ls="ls -F -G"
else
    alias ls="ls -h --file-type --color=auto"
    
    # don't delete / or prompt if deleting more than 3 files at a time #
    alias rm='rm -I --preserve-root'
fi







# undoc

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
        test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

