#! /bin/bash

# http://kunhsien.blogspot.tw/2013/11/linuxubuntu.html

sudo fdisk -l #： 列出硬碟分割區

# kernel version
uname -r # kernel version 
uname -s # kernel name , Linux Darwin
uname -m # machine  , x86_64
uname -p # processor , x86_64 
uanme -i # hardware , x86_64 , don't work for mac
uname -o # os , GNU/Linux , don't work for mac



# login user list , 單純顯示登入數 ＋各個帳號與登入時間
who -q
users

who -T

# system disk 
echo "--- system disk ---"
df -h

# du -sh *
tree -h 



# cpu
lscpu
nproc , show how many cores of cpu
cat /proc/cpuinfo

# memory
free -h 
free -th
cat /proc/meminfo

# network 

uptime


sudo rkhunter --checkall：消滅木馬程式

# network i/o mb

# network request number



http://www.tecmint.com/command-line-tools-to-monitor-linux-performance/
google :linux how to monitor system performance



self port list


**********com*
http://www.coctec.com/docs/linux/show-post-45715.html

[shuk@shuk]/home/shuk$ vim /var/lo/rkhunter.log
[shuk@shuk]/home/shuk$ vim /var/log/rkhunter.log
[shuk@shuk]/home/shuk$ sudo vim /var/log/rkhunter.log
[shuk@shuk]/home/shuk$ sudo vim /var/log/rkhunter.log



umask

### umask
default file permission

ex: umask 022

