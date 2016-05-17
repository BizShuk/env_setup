
sudo apt-get install mysql-server


### setup

1. wget https://go.googlecode.com/files/go1.2.1.linux-amd64.tar.gz

2. `echo  "PATH=/usr/local/go/bin:$PATH" >> .bashrc`

3. `go version`

4. download gogs binary and untar it

7.

```
cd gogs;
./gogs web;
```

原始目錄會在 gogs 接著可以看到 conf/app.ini 原始設定檔，官方建議不要修改此檔案，使用者可以自行建立 custom/conf/app.ini 來取代原始設定內容。最後執行 ./gogs web


### cmd
- ./gogs dump
    dump sql query and all repository files , NOTE: create of sql query is without tail semicolon
- ./gogs web


### configuration

- first account is administrator who get admin panel  
    user authorization , server configuration
- if you setup a hook manually(pre-receive must do it manually , others by admin)  , you should make excutable `chmod +x hook_file`












