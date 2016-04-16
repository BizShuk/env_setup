#!/bin/bash
source settings.sh

# update and upgrade
sudo apt-get update && apt-get upgrade -y

# install package
sudo apt-get install curl wget build-essential screen colordiff python-dev python3-dev -y



# install server package
sudo apt-get install openssh-server libssl-dev -y


# unnessesary
sudo apt-get install -y dnsutils

exit 0;
