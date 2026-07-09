#!/bin/bash

## alias cmd ##
#ref: [30 Handy Bash Shell Aliases](http://www.cyberciti.biz/tips/bash-aliases-mac-centos-linux-unix.html)

## code ##
if which python3 >/dev/null; then
    alias python='python3'
    alias python-config='python3-config'
else
    alias python='python2.7'
    alias python-config='python2.7-config'
fi

alias py-config='python-config'

## system operator ##
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
alias grep='grep --color=auto -e' # -x , line-regexp  ,  -i , ignore case  , -n , show line number
alias fgrep='fgrep --color=auto'
if [ "$os" == "darwin" ]; then
    alias grep='egrep --color=auto'
fi
alias e='egrep --color=auto'
alias vi='vim'
alias edit='vim'
alias ping='ping -c 5'            # Stop after sending count ECHO_REQUEST packets
alias pingfast='ping -c 100 -s.2' # Do not wait interval 1 second, go fast
alias wget='wget --show-progress'
# confirmation #
#alias mv='mv -i'
#alias cp='cp -i'
#alias ln='ln -i'
alias diff='colordiff'

## ls ##
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

## New CMDs ##
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowtime=now
alias nowdate='date +"%d-%m-%Y"'
alias tree='tree -N --noreport'
alias mdtree="tree -f --charset utf8 | sed -E  -e 's:\./::g' -e 's:─ (.*)/(.*)$:─ [\2](\1/\2):g' -e 's/^(.── )(.*)$/\1[\2](\2)/g' -e 's/$/  /g'"
alias genREADME='echo $(basename $(pwd)) >README.md; mdtree >> README.md'


## Npm ##
alias lt1="config ls -l"

# undoc

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

## Music player : mplayer
alias music_play="mplyaer -shuffle -- */**.mp3"

alias oc="openclaw"
alias ocl="openclaw logs --follow"
alias pc="picoclaw"

alias jieli="HUB_URL=https://hl9h6ru7.fn-boe.bytedance.net jieli"


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





# 載入個人化私密環境變數/密碼 (若 ~/.bash_local 存在)
if [ -f "${HOME}/.bash_local" ]; then
    # shellcheck disable=SC1090
    . "${HOME}/.bash_local"
fi

alias claude="claude --allow-dangerously-skip-permissions --settings ~/projects/cc-plugin/config/settings.json"
# 以下 claudew-s / claudew-b / claudew2 alias 依賴私密 API token (TIKTOK_API_KEY, TIKTOK_API_KEY2 等),
# 為避免 token 進入 git, 改放至 git-ignored 的 ~/.bash_local。
# 基礎 claudew / claudem 已提升為 bin/claudew 與 bin/claudem 實體 script file (取代 alias 以避免 alias 限制)。
# 範本 (snippet) 可參考 docs/notes/bash-local-aliases.md。
alias codexm='codex --profile m3'

alias claudew-s='ANTHROPIC_AUTH_TOKEN=$TIKTOK_API_KEY claude --allow-dangerously-skip-permissions --effort max --model glm-5.2 --settings ~/projects/cc-plugin/config/llmbox.json -p "look whole project for consistency, remove redundancy, structural, scalable. make a plan to ./plans/ and add an entry in README.todo"'
alias claudew-b='ANTHROPIC_AUTH_TOKEN=$TIKTOK_API_KEY claude --allow-dangerously-skip-permissions --effort max --model glm-5.2 --settings ~/projects/cc-plugin/config/llmbox.json -p "evlauate current business scope and find out high value aspects. make a plan to ./plans/ and add an entry in README.todo"'
alias claudew2='ANTHROPIC_AUTH_TOKEN=$TIKTOK_API_KEY2 claude --allow-dangerously-skip-permissions --settings ~/projects/cc-plugin/config/llmbox.json'


# 載入個人化 alias (若 ~/.bash_local 存在)
if [ -f "${HOME}/.bash_local" ]; then
    # shellcheck disable=SC1090
    . "${HOME}/.bash_local"
fi

