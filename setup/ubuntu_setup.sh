#!/bin/bash
. settings.sh


#####
##### Apt-get
#####

# Update and Upgrade
sudo apt-get update && apt-get upgrade -y

# Dev package
sudo apt-get install -y build-essential
sudo apt-get install -y python-dev python3-dev
sudo apt-get install -y openssh-server libssl-dev

# User
# jq ,https://stedolan.github.io/jq/tutorial/
sudo apt-get install -y jq
sudo apt-get install -y screen colordiff wget curl

# unnessesary
sudo apt-get install -y dnsutils
sudo apt-get install -y ibus-chewing    # 新酷音



#####
##### Locale
#####
sudo locale-gen zh_TW.UTF-8 zh_TW.BIG5 en_US.UTF-8

sudo update-locale LANG="en_US.UTF-8"           # defaul locale if not found
sudo update-locale LANGUAGE="en_US.UTF-8"
sudo update-locale LC_CTYPE="zh_TW.UTF-8"      # 這會影響字元的分類和轉換，若要能輸入中文
sudo update-locale LC_NUMERIC="en_US.UTF-8"
sudo update-locale LC_TIME="en_US.UTF-8"        # 這就是日期和時間的顯示格式囉
sudo update-locale LC_COLLATE="en_US.UTF-8"
sudo update-locale LC_MONETARY="en_US.UTF-8"   # 這會影響貨幣單位的符號和表示
sudo update-locale LC_MESSAGES="en_US.UTF-8"   # 這會影響系統訊息的顯示，若想要顯示中文，
sudo update-locale LC_PAPER="en_US.UTF-8"
sudo update-locale LC_NAME="en_US.UTF-8"
sudo update-locale LC_ADDRESSE="en_US.UTF-8"
sudo update-locale LC_TELEPHONE="en_US.UTF-8"
sudo update-locale LC_MEASUREMENT="en_US.UTF-8"
sudo update-locale LC_IDENTICFICATION="etn_US.UTF-8"
sudo update-locale LC_ALL=""        # 這是強制全部使用這裡的設定


#####
##### Timezone
#####
sudo cp /usr/share/zoneinfo/Asia/Taipei /etc/localtime


#####
##### Add account
#####
id -u shuk
if [ "$?" != "0" ]; then
    sudo useradd shuk -m -s /bin/bash
    sudo passwd shuk
    ## ?? echo 'userid:newpasswd' | chpasswd
    ## ?? usermod --password PASSWORD USERNAME
fi


#####
##### Docker
#####
echo "Do you want to install Docker [ y/n(default) ]"
read intall_docker
install_docker=`echo "$install_docker" | tr '[:upper:]' '[:lower:]'`
[ "$install_docker" == "y" ] && . ./ubuntu_docker.sh


#####
##### postgre sql
#####
./ubuntu_postgres.sh



#####
##### Activate service
#####
sudo service ssh start;


