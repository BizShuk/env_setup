
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


# network
bmon


# system

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

### memcpu

# System

### who
- -q , show login name list
- -T , show detail of all login user



### umask
default file permission

ex: umask 022


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
















