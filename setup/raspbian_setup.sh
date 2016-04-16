#!/bin/bash



sudo apt-get update && upgrade -y

# config cmd : raspi-config
# file resize , by cmd how?
# locale-gen

cd ~
sudo apt-get install -y git 

git clone https://github.com/bizshuk/env_setup

cd env_setup/setup/

sudo ./ubuntu_package.sh
sudo ./ubuntu_locale.sh
sudo ./ubuntu_shuk_account.sh
./bash_env.sh
./nginx_setup.sh
