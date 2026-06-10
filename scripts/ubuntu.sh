#!/bin/bash
set -euo pipefail
. "$(dirname "$0")/settings.sh"


#####
##### Apt-get
#####

# Update and Upgrade
sudo apt-get update && sudo apt-get upgrade -y

# Dev package
sudo apt-get install -y build-essential update-locale locales
sudo apt-get install -y autoconf make cmake
sudo apt-get install -y python3-dev
sudo apt-get install -y openssh-server libssl-dev
sudo apt-get install -y whois



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
sudo locale-gen zh_TW.UTF-8 en_US.UTF-8

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
sudo update-locale LC_ADDRESS="en_US.UTF-8"
sudo update-locale LC_TELEPHONE="en_US.UTF-8"
sudo update-locale LC_MEASUREMENT="en_US.UTF-8"
sudo update-locale LC_IDENTIFICATION="en_US.UTF-8"
sudo update-locale LC_ALL=""        # 這是強制全部使用這裡的設定


#####
##### Timezone
#####
sudo cp /usr/share/zoneinfo/Asia/Taipei /etc/localtime


#####
##### Add user and group
#####
if ! id -u "$user" &>/dev/null; then
    sudo useradd "$user" -m -s /bin/bash
    sudo passwd "$user"
    ## ?? echo 'userid:newpasswd' | chpasswd
    ## ?? usermod --password PASSWORD USERNAME
fi

if ! getent group "$user" &>/dev/null; then
    sudo groupadd "$user"
fi

#####
##### Activate service
#####
#sudo service ssh start;


