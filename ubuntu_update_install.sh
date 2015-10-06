#!/bin/bash

# update and upgrade
apt-get update && apt-get upgrade -y

# install package
apt-get install git vim curl wget build-essential screen openssh-server -y

service ssh start;
