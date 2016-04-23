# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

source settings.sh


## If not running interactively, don't do anything ##
[ -z "$PS1" ] && return

## customized env
export dr="dr:5000"

## locale
export LANG="en_US.UTF-8"

## set default env varaible ##
export TERM="xterm-256color"
export PATH=$bin_dir:$PATH;
#export CDPATH=.:$HOME:$project_dir;
export PS1='\[$(tput bold)\]\[$(tput setaf 7)\][\[$(tput setaf 2)\]\u\[$(tput setaf 7)\]@\[$(tput setaf 6)\]\h\[$(tput setaf 7)\]]\[$(tput setaf 2)\]$PWD\[$(tput setaf 7)\]\$\[$(tput sgr0)\] '

## set default editor ##
export EDITOR=vim
export VISUAL=vim
export SVN_EDITOR="$VISUAL"




## About history. Set history length via HISTSIZE and HISTFILESIZE ##

# Dont put duplicate lines in the history
#HISTCONTROL=ignoreboth

# Ignore these commands
#HISTIGNORE="reboot:shutdown *:ls:pwd:exit:mount:man *:history"

export HISTSIZE=10000
export HISTFILESIZE=1000

# Add timestamp to history file. #
export HISTTIMEFORMAT="%F %T "

#Append to history, don't overwrite
shopt -s histappend



## shell timeout for security ##
#export TMOUT=300

## Set default file permission to 644 ##
#umask 022


# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend



## undoc yet
# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
  # We have color support; assume it's compliant with Ecma-48
  # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
  # a case would tend to support setf rather than setaf.)
  color_prompt=yes
    else
  color_prompt=
    fi
fi


## Alias definitions. ## See /usr/share/doc/bash-doc/examples in the bash-doc package.
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

## Bash function ##
[ -f ~/.bash_function ] && . ~/.bash_function

## Bash plugin ## (for something like 3th-party export)
[ -f ~/.bash_plugin ] && . ~/.bash_plugin


## enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi


