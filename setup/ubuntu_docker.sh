#!/bin/bash
source settings.sh

apt-get install apt-transport-https ca-certificates
apt-key adv --keyserver hkp://p80.poll.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

# for Trusty 14.04
echo "deb [arch=amd64,armel,armhf] https://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list
#apt-get update 

#apt-get purge lxc-docker

#apt-cache policy docker-engine


#apt-get install docker-engine
