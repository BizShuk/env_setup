### desktop_setup

##### ubuntu mate Gui
```
sudo apt-add-repository ppa:ubuntu-mate-dev/ppa
sudo apt-add-repository ppa:ubuntu-mate-dev/trusty-mate
sudo apt-get update && sudo apt-get upgrade
sudo apt-get install --no-install-recommends ubuntu-mate-core ubuntu-mate-desktop
```


##### wine
透過指令刪除以下資料夾內的Wine相關檔案
```
rm -rf ~/.wine/
rm -rf ~/.config/menus/applications-merged/wine*
rm -rf ~/.local/share/applications/wine*
rm -rf ~/.local/share/desktop-directories/wine*
```
接著利用指令安裝wine 1.6
```
sudo add-apt-repository ppa:ubuntu-wine/ppa
sudo apt-get update
sudo apt-get install wine 1.6
```

##### line 
1. download  PC version exe
2. right click on  it and select `wine` to open 
