ubuntu settings
=====

## undoc
boot up service
  ex:sudo update-rc.d [apache2/cmd] [enable/disable]
find ./ -type f -exec sed -i 's/string1/string2/' {} \;


## sed
- -r , for regex

## awk
awk 'NR == 10 { print $1 }'
awk 'NR  < 10 { print $1 }'



### # undoc cmd

### # system info
`uname -r`
kernel version

`lsb_release -a`
ubuntu version

### # unity tweak tool
install "unity tweak tool" in software center 
system => display



### package installation
- dkpg -L packagename
	get location of package
- dkpg -l | grep xxxx
	package list and grep

### paticular note
- port less than 1024 , used by root only
- 清除^M , `cat filename | tr -d '\r' > newfilename`



## about system

##### locale 語系
`etc/default/locale`

##### shutdown
`shutdown [-h time] [-r now]`
- -r , for reboot

##### disk
df -h 可知道目前硬碟剩餘空間與使用空間
  => alias to disk_size
du -sh * 可知目前此資料夾各檔案總共佔用硬碟大小總數，以G為單位
    => alias to dir_size

du
--max-depth=1
-h , human readable
-s , for summary

ex:
du -sh
du -sh *


## sort
- -k , column index
- -g , compare with numeric sort
- -n , compare wtih string numeric sort
    4   12
    12   4
    0    0
- -r , reverse
- -h , compare with human readable numeric , ex: 10G 10M 4K
- -f , 忽略大小寫
- 

example:
    sort -k 3 -n 

## sort


## dirs
##### pushd
`pushed path`  
cd to path and push to stack

##### popd
`popd`
pop out path of now , and cd to last in th stack

##### dirs
`dirs`  
show dirs in the stack

#####  mktemp
???
create tmp file or dir
  -d , for dir
  -u , don't create , just print
  --tmpdir=/path/to/dir
  -t , create under --tmpdir
  -p dir , equal  -t + --tmpdir






## about user
related files
- /etc/adduser.conf
- /etc/passwd
    在/etc/passwd裡面, 改變預設shell
    ex: bob:x:1001:1001::/home/bob:/bin/bash
- /etc/group
- cp /etc/skel to user dir
- /etc/shadow


##### useradd 
( Account不能使用底線 )  

    useradd username [-d homedir](use as homedir) [-s shell] [-g groupname]  [-m](create homedir)
    ex: `sudo useradd shuk -m -G shuk,sudo,git -s "/bin/bash"`

##### change password
`passwd <username>`

##### create group
`groupadd <groupname>`

##### append groups
`usermod -G <groupname> <username>`

##### # chang mods
`chmod -R xyz (file or dir) ,# xyz為(owner,group,others)三種權限 , -R:recursive`
`chown -R account:groupname (file or dir) # -R:recursive`
`chgrp  -R (file or dir) # -R:recursive`
-R  for recursive






## # tar 
http://www.vixual.net/blog/archives/127
http://note.drx.tw/2008/04/command.html

    tar -c [-f sourcedir ] [dest.tar ]    # 壓縮
    tar -x [-f source.tar] [-C destdir ]  # 解壓縮
-o <output file>





## SSH

##### cert flow
send private key to ssh server , and ssh server use public key to verify it 

1. create key
2. copy public key to remote ~/.ssh/authorized_keys 

##### cert verify
`ssh-copy-id [username]@hostname` , default use ~/.ssh/id_rsa or ssh-agent identity

##### add identity to ssh agent
1. start agent first `ssh-agent -s`
2. add cert to agent `ssh-add [file]` , default using ~/.ssh/id_rsa ... (many default file)etc

##### ssh config
default configuration 
`/etc/ssh/sshd_config`

    PermitRootLogin no # retrict root login
    RSAAuthentication yes # use rsa auth 
    PubkeyAuthentication yes # use public key auth 
    AuthorizedKeysFile     .ssh/authorized_keys # default auth file location
    PasswordAuthentication no # use password for auth

##### ssh-keygen
ssh-keygen -t rsa 或 ssh-keygen -d (dsa)

##### retrict user
vi /etc/pam.d/sshd
        auth       required     pam_listfile.so item=user sense=allow file=/etc/ssh_users
echo user1 >> /etc/ssh_users

#####

 
3) 限制 su / sudo 名單:
# vi /etc/pam.d/su
        auth       required     /lib/security/$ISA/pam_wheel.so use_uid
# visudo
        %wheel  ALL=(ALL)       ALL
# gpasswd -a user1 wheel



 


## crontab
### crontab config
檔案位置`/etc/cron.*/``


### crontab format
    -  *  *  *  *     date >> /tmp/date
    分 時 日 月 周      執行的命令
    # file shoud be execuable
    minute         0-59
    hour           0-23
    day of month   1-31
    month          1-12 (or names, see below)
    day of week    0-7 (0 or 7 is Sun, or use names)

ex: `*/5 10 * * *     [執行的命令]` => 早上10點 每5分鐘執行一次

### crontab cmd
##### show crontab job list
`crontab -l` 




