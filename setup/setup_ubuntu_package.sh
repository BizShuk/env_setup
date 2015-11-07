#!/bin/bash
source settings.sh

# update and upgrade
apt-get update && apt-get upgrade -y

# install package
apt-get install git vim curl wget build-essential screen -y

# install server package
apt-get install openssh-server -y

# install docker
curl -sSL https://get.docker.com/ | sh

docker pull bizshuk/env_setup
docker tag bizshuk/env_setup  base

exit 0;