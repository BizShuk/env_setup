#!/bin/bash


os="$(uname)"

# system monitort
alias p="ps axu"        # show process list
alias t="top"           # show top process using most resources

# size of disks , dirs , and files
#   -h , for human readable
#   -s , for summary
#
alias disk_size="df -h"
alias file_size="du -sh *"  
alias dir_size="du -sh"



# may have problem
#alias dir='dir --color=auto'        # = ls  
#alias vdir='vdir --color=auto'      # = ls -l 
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'



# ls
#   -F = --file-type , show different with file type
#   -G = --color=auto , with color

if [ "$os" == "Darwin" ]; then
    alias ls="ls -F -G"
else
    alias ls="ls --file-type --color=auto"
fi







# undoc

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
        test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

