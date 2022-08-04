#!/bin/bash
source settings.sh


sudo apt-get update

wget -qO- https://get.docker.com/ | sh


#sudo apt-get install apt-transport-https ca-certificates
#sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58
#echo 'deb https://apt.dockerproject.org/repo ubuntu-trusty main' | sudo tee /etc
#sudo apt-get update
#sudo apt-get install -y docker-engine
#sudo apt-get purge lxc-docker
#sudo apt-cache policy docker-engine
cat $REPO_PKG/docker/docker | sudo tee -a /etc/default/docker

sudo service docker restart


# for Trusty 14.04
#echo "deb [arch=amd64,armel,armhf] https://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list
