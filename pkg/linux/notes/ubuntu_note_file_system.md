
ref. [link](http://tobala.net/x/Linux2008/Linux-01SYS-200906.html)
- 檔案系統
- 程序管理

### install exFat file system
`sudo apt-get install exfat-fuse exfat-utils`


##### # disk partition and format

    名稱     裝置名稱     檔案系統編號     建議容量        註解
    ---------------------------------------------------------------------------
    C:      /dev/hda1   (NTFS 7)       2G - 4G        
    Window 基本系統
    
    /boot   /dev/hda2   (ext2 83)      5M - 30M       
    boot 磁區建議安排在硬碟 1024 軌之內，如不很清楚請儘量安排在硬碟的開頭部份，如果往後希望安裝GRUB 請將硬碟配置約 30M 左右。
    
    /       /dev/hda3   (ext2 83)      400M - 500M    
    UNIX 樹狀起始目錄，最小作業所需。

    --------/dev/hda4 ------------------------------- 硬碟延伸磁區，底下為邏輯磁區

    swap    /dev/hda5   (swap 82)      
    2 倍記憶體大小
    
    /usr    /dev/hda6   (ext2 83)      
    2G - 4G 使用者應用程式存放區，包含圖形使用者介面，網路伺服器軟體，常用工具等。

    /var    /dev/hda7   (ext2 83)      400M - 500M    系統日誌資訊，郵件暫存區，印表機暫存區，系統套件安裝資訊資料庫，安裝應用套件暫存區

    /home   /dev/hda8   (ext2 83)      2G - 100G      使用者自身存放資料區域，視使用者自身資料量的多寡自由定義，建議 2G 以上

    D:      /dev/hda9   (FAT32 b)      4G - 100G      Window 應用程式以及個人資料存放區，視使用者資料量的多寡自行定義硬碟大小，建議 4G 以上


### fdisk and format
list partition tables
`fdisk -l`


### find file
find [location . ]
	-type f 	=> file only
	-user username => owner
	-name => search name

Execute command on all files

	Run ls -l command on all *.c files to get extended information :
	`find . -name "*.c" -type f -exec ls -l {} \;`

	You can run almost all UNIX command on file. For example, modify all permissions of all files to 0700 only in ~/code directory:
	`find ~/code -exec chmod 0700 {} \;`



### file system

### mount

### # filesystem , must root or sudo
還沒mount到dir的時候 才可以格式化

格式化
`sudo mkfs -t ext4 /dev/sxx`

mount
`sudo mount /dev/sda1 /path/you/want`

umount
`sudo umount /path/you/mount`

改變權限
chown or chmod


### # samba server
    ref. [link](http://www.snjh.tc.edu.tw/~cmlee/doc/server/samba.htm)

```
    sudo apt-get install samba
```

edit /etc/samba/smb.conf( where is it ? )
```
// for [global]
    workgroup = pi          # window 顯是工作群組
    security = share        # share:不需要帳號密碼, user:需要本機驗證帳號密碼 , server:由其他台驗證帳號密碼, domain:由window伺服器來驗證帳號密碼

// 尾部加入  for \\192.168.x.x\public
    [public]                # 資料夾明稱
    path = /home/pi/samba   # 資料夾路徑
    writable = yes
    guest account = pi
    force user = pi
    public = yes
    force group = pi
```

`sudo /etc/init.d/samba restart`


##### # mount client
mount -t cifs -o username="Username",password="Password" //IP/share /mnt/smb
umount /mnt/smb

mount.cifs -o username="Username",password="Password" //IP/share /mnt/smb
umount.cifs /mnt/smb





