#!/bin/bash

# ref: [30 Handy Bash Shell Aliases](http://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html)

## Local Environment Variables ##
# 載入個人化私密環境變數/密碼 (若 ~/.bash_local 存在，於 alias 定義前載入)
if [ -f "${HOME}/.bash_local" ]; then
    # shellcheck disable=SC1090
    . "${HOME}/.bash_local"
fi

## System & Process Management ##
alias update='sudo apt-get update && sudo apt-get upgrade'
alias shutdown_reboot='sudo /sbin/reboot'
alias shutdown_poweroff='sudo /sbin/poweroff'
alias shutdown_halt='sudo /sbin/halt'
alias shutdown='sudo /sbin/shutdown'

alias p="ps axu" # show process list
alias t="top"    # show top process using most resources
alias h='history'
alias j='jobs -l'

# don't change /'s owner group and mod
#alias chown='chown --preserve-root'
#alias chmod='chmod --preserve-root'
#alias chgrp='chgrp --preserve-root'

## Disk & Storage ##
#   -h , for human readable
#   -s , for summary
alias disk_size="df -h"
alias file_size="du -sh *"
alias dir_size="du -sh"
if [ "$os" != "darwin" ]; then
    alias lsblk='lsblk -e 7 -o NAME,SIZE,FSTYPE,FSAVAIL,FSUSE%,LABEL,MOUNTPOINT,TRAN,MODEL'
fi

## File & Directory Listing ##
# enable color support of ls
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

#   -F = --file-type , show different with file type
#   -G = --color=auto , with color
if [ "$os" == "darwin" ]; then
    alias ls="ls -h -F -G"
else
    alias ls="ls -h --file-type --color=auto"

    # don't delete / or prompt if deleting more than 3 files at a time #
    #alias rm='rm -I --preserve-root'
fi
alias ll="ls -lF --color=auto"
alias tree='tree -N --noreport'
#alias dir='dir --color=auto'        # = ls
#alias vdir='vdir --color=auto'      # = ls -l

## File Editing & Safety ##
alias vi='vim'
alias edit='vim'
alias diff='colordiff'
# confirmation #
#alias mv='mv -i'
#alias cp='cp -i'
#alias ln='ln -i'

## Search (grep) ##
alias grep='grep --color=auto -e' # -x , line-regexp  ,  -i , ignore case  , -n , show line number
alias fgrep='fgrep --color=auto'
if [ "$os" == "darwin" ]; then
    alias grep='egrep --color=auto'
fi
alias e='egrep --color=auto'

## Network & Tunneling ##
alias ping='ping -c 5'            # Stop after sending count ECHO_REQUEST packets
alias pingfast='ping -c 100 -s.2' # Do not wait interval 1 second, go fast
alias wget='wget --show-progress'
alias cf="cloudflared"

## Shell Utilities & Time ##
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowtime=now
alias nowdate='date +"%d-%m-%Y"'

## Documentation & Markdown ##
alias mdtree="tree -f --charset utf8 | sed -E  -e 's:\./::g' -e 's:─ (.*)/(.*)$:─ [\2](\1/\2):g' -e 's/^(.── )(.*)$/\1[\2](\2)/g' -e 's/$/  /g'"
alias genREADME='echo $(basename $(pwd)) >README.md; mdtree >> README.md'

## Development & Python ##
if which python3 >/dev/null; then
    alias python='python3'
    alias python-config='python3-config'
else
    alias python='python2.7'
    alias python-config='python2.7-config'
fi
alias py-config='python-config'

# 取得 Python 設定路徑 (Get Python configuration directory)
get_python-config-dir () {
    if ! command -v python-config > /dev/null; then
        echo "python-config is not installed"
        return 127
    fi

    # 取得第一個參數並移除開頭的 -L (Get the first flag and remove -L prefix)
    python_config_dir=$(python-config --ldflags | awk '{print $1}')
    python_config_dir=${python_config_dir:2}

    echo "${python_config_dir}"
}

alias lt1="config ls -l"

## Media ##
# Music player : mplayer
alias music_play="mplyaer -shuffle -- */**.mp3"


# 載入 LLM CLI alias (claude / codex 各 provider profile)
# 來源 (owner): ~/projects/ai/cc-plugin/scripts/aliases.sh
if [ -f "${HOME}/projects/ai/cc-plugin/scripts/aliases.sh" ]; then
    # shellcheck disable=SC1090
    . "${HOME}/projects/ai/cc-plugin/scripts/aliases.sh"
fi
