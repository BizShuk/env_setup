# cmd usage
undoc list:
- dmesg
- 


### cd

- `cd -` , switch with your last directory
- `cd ~` = `cd` , to home directory
- 

### readlink
`readlink [options]... [Files]...` , read symbolic link recursively to target
- -f , show all target path
- -e , show all existed targets
- -m , ?not sure

for Mac
- -n , show in one line


### find
find --help



# network
bmon


### ip
[link](http://www.tecmint.com/ip-command-examples/)


### route 

### br

### ifdown and ifup


###

# system

### kill
http://www.linux.org/threads/kill-commands-and-signals.4423/


### utp
time server

service:
- /etc/init.d/ntp [start|stop|restart]

related:
- /etc/ntp.conf
- /etc/localtime
- /usr/share/zoneinfo/Asia/Taipei
- /etc/timezone

### ntpdate 
set ntp server
ex: ntpdate <server>


### ulimit
limit resource 
- -a , show limitation of this shell
- 

related:
- /etc/security/limits.conf


### locale 
- none , 顯示目前語系設定
- 
- -a , 列出系統已經安裝的語系

use locale-gen 安裝語系

LC_CTYPE 這會影響字元的分類和轉換，若要能輸入中文，就是設定這裡
LC_TIME 這就是日期和時間的顯示格式囉
LC_MONETARY 這會影響貨幣單位的符號和表示
LC_MESSAGES 這會影響系統訊息的顯示，若想要顯示中文，就是設定這裡
LANG 這是預設，如果上面有沒設定的，就會用這裡的設定
LC_ALL 這是強制全部使用這裡的設定，如果這裡設定了，那麼上面的都沒用，全部以這裡的為準

若要變更的是系統全域設定，那麼就把設定寫在 /etc/default/locale 這個檔案裡
$ sudo vim /etc/default/locale
LC_CTYPE=zh_TW.UTF-8
LC_MESSAGES=zh_TW.UTF-8
LC_TIME=zh_TW.UTF-8
或者加到環境變數的設定檔 /etc/environment 最後面
$ sudo vim /etc/environment
....(略)...
LC_CTYPE=zh_TW.UTF-8
LC_MESSAGES=zh_TW.UTF-8
LC_TIME=en_US.UTF-8

### locale-gen
install locale 

e.g. `sudo locale-gen zh_TW.UTF-8 zh_CN.UTF-8 ...`


# System monitor
 now in bin/system_performance


### chmod 
change authorization 
`drwxrwxrwx`
d , directory or not  
r , owner readable  
w , owner writable  
x , owner executable  
r , group readable  
w , group writable  
x , group executable  
r , other readable  
w , other writable  
x , other executable  


`chmod 0000 <directory>` , lock directory but only root can access















### apt-get 
server domain unavailable , change /etc/apt/source.list to other link
in China : [list](http://wiki.ubuntu.org.cn/%E6%BA%90%E5%88%97%E8%A1%A8)


### crontab


crontab file sample:
```

@reboot <username> <command>
```




### SSH

1. ssh-keygen ,  
```
jsmith@local-host$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/home/jsmith/.ssh/id_rsa):[Enter key]
Enter passphrase (empty for no passphrase): [Press enter key]
Enter same passphrase again: [Pess enter key]
Your identification has been saved in /home/jsmith/.ssh/id_rsa.
Your public key has been saved in /home/jsmith/.ssh/id_rsa.pub.
The key fingerprint is:
33:b3:fe:af:95:95:18:11:31:d5:de:96:2f:f2:35:f9 jsmith@local-host
```

2. ssh-copy-id [-i <key.pub>] <remote_host>  

    1. Default public key: ssh-copy-id uses ~/.ssh/identity.pub as the default public key file (i.e when no value is passed to option -i). Instead, I wish it uses id_dsa.pub, or id_rsa.pub, or identity.pub as default keys. i.e If any one of them exist, it should copy that to the remote-host. If two or three of them exist, it should copy identity.pub as default.
    2. The agent has no identities: When the ssh-agent is running and the ssh-add -L returns “The agent has no identities” (i.e no keys are added to the ssh-agent), the ssh-copy-id will still copy the message “The agent has no identities” to the remote-host’s authorized_keys entry.
    3. Duplicate entry in authorized_keys: I wish ssh-copy-id validates duplicate entry on the remote-host’s authorized_keys. If you execute ssh-copy-id multiple times on the local-host, it will keep appending the same key on the remote-host’s authorized_keys file without checking for duplicates. Even with duplicate entries everything works as expected. But, I would like to have my authorized_keys file clutter free.



##### remove ssh key for host
ssh-keygen -R <host>


Another way by ssh-agent , ssh-add
How to do it?



### rsync
sync file or directory to other place


-a , archive mode
-v , verbose
-h , human readble
-P , show copy progress
-n , dry-run

--delete , delete extraneous files from dest dirs
--exclude , exclude file
--include , include file

### samba

- install samba with `sudo apt-get install samba samba-common`
- configure /etc/samba/smb.conf , sample in `server_config/smb.conf` and server_config/smb_note.conf
- restart service smbd

You can set samba user by `smbpasswd -a <user>` and check log at /var/log/samba


### file system


##### mount 

mount -t \<fs format\> \<disk\> \<directory\>


`/etc/fstab` for automount at bootup , you can check disk UUID and add a line here. It will mount at boot up


for exfat , apt-get install exfat-fuse exfat-utils


##### df
check report file system on disk

-T , print type

##### blkid -s UUID
-s UUID , show all mounted disk UUID

##### lsblk
list block devices, show all device ,including partition , with tree struction


##### fsck
check disk situation and it will ask few questions like "Do you want to recover disk?"

1. umount disk first
2. fsck -yf \<device\>


- -y , yes for all questions
- -f , force checking 
- -p , automatic repair


##### fdisk
partition

- -l , list all disks , same functionality as lsblk
- \<disk\> , operate with that device





##### parted
same as fdisk , but by GNU

parted /dev/sda unit TB print free


### lvm 2

##### pv

##### vg

##### lv



##### lsusb
list USB devices



### openssl

```
openssl genrsa -aes256 -out \<file_name\> 4096
type pass phase
```

openssl verify -CAfile="" -in <crt_file> -text -noout


### package

##### dpkg
-l , show all packages
-L <package_name> , show all package files


##### pkg-config
PKG_CONFIG_PATH 
*.pc file



##### 

