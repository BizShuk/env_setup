#!/bin/bash

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

source ~/settings.sh

# Bash hotkey
# - ctrl + a,   Move to the start of the command line
# - ctrl + e,   Move to the end of the command line
# - ctrl + b,   Move one character backward
# - ctrl + f,   Move one character forward
# - ctrl + r,   Incremental reverse search of bash history
# - ctrl + w, 	Removes the command/argument before the cursor

## If not running interactively, don't do anything ##
[ -z "$PS1" ] && return

## locale
export LANG="en_US.UTF-8"

## set default env varaible ##
export TERM="xterm-256color"
export PATH=${HOME}/.local/bin:${HOME}/bin:$PATH
#export CDPATH=.:$HOME:$project_dir;
export PS1='\[$(tput bold)\]\[$(tput setaf 7)\][\[$(tput setaf 2)\]\u\[$(tput setaf 7)\]@\[$(tput setaf 6)\]\h\[$(tput setaf 7)\]]\[$(tput setaf 2)\]$PWD\[$(tput setaf 7)\]\$\[$(tput sgr0)\] '

#Foreground & background colour commands
#tput setab [1-7] # Set the background colour using ANSI escape
#tput setaf [1-7] # Set the foreground colour using ANSI escape

#Num  Colour    #define         R G B
#0    black     COLOR_BLACK     0,0,0
#1    red       COLOR_RED       1,0,0
#2    green     COLOR_GREEN     0,1,0
#3    yellow    COLOR_YELLOW    1,1,0
#4    blue      COLOR_BLUE      0,0,1
#5    magenta   COLOR_MAGENTA   1,0,1
#6    cyan      COLOR_CYAN      0,1,1
#7    white     COLOR_WHITE     1,1,1

#Text mode commands
#tput bold    # Select bold mode
#tput dim     # Select dim (half-bright) mode
#tput smul    # Enable underline mode
#tput rmul    # Disable underline mode
#tput rev     # Turn on reverse video mode
#tput smso    # Enter standout (bold) mode
#tput rmso    # Exit standout mode

#Cursor movement commands
#tput cup Y X # Move cursor to screen postion X,Y (top left is 0,0)
#tput cuf N   # Move N characters forward (right)
#tput cub N   # Move N characters back (left)
#tput cuu N   # Move N lines up
#tput ll      # Move to last line, first column (if no cup)
#tput sc      # Save the cursor position
#tput rc      # Restore the cursor position
#tput lines   # Output the number of lines of the terminal
#tput cols    # Output the number of columns of the terminal

#Clear and insert commands
#tput ech N   # Erase N characters
#tput clear   # Clear screen and move the cursor to 0,0
#tput el 1    # Clear to beginning of line
#tput el      # Clear to end of line
#tput ed      # Clear to end of screen
#tput ich N   # Insert N characters (moves rest of line forward!)
#tput il N    # Insert N lines

#Other commands
#tput sgr0    # Reset text format to the terminal's default
#tput bel     # Play a bell

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
xterm-color) color_prompt=yes ;;
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
    export color_prompt=yes
  else
    export color_prompt=no
  fi
fi

# Bash config
[ -f ~/.bash_aliases ] && source "${HOME}/.bash_aliases"   # Alias for existing command
[ -f ~/.bash_function ] && source "${HOME}/.bash_function" # Custom bash function
[ -f ~/.bash_plugin ] && source "${HOME}/.bash_plugin"     # Third-party config

## enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
  source /etc/bash_completion 2>/dev/null
fi

# Use bash-completion, if available
[[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] &&
  source /usr/share/bash-completion/bash_completion 2>/dev/null

# Automatically Logout BASH / TCSH / SSH Users After a Period of Inactivity

# for linux
#TMOUT=300
#readonly TMOUT
#export TMOUT

### for tcsh/csh
#set -r autologout 5

### for ssh clients at /etc/ssh/sshd_config
#ClientAliveInterval 300
#ClientAliveCountMax 0

# supress zsh in mac
export BASH_SILENCE_DEPRECATION_WARNING=1
export PATH=$HOME/.local/bin:$PATH
