#!/bin/bash
source settings.sh

# update and upgrade
apt-get update && apt-get upgrade -y

# install package
apt-get install  curl wget build-essential screen colordiff -y

# install server package
apt-get install openssh-server -y




exit 0;
