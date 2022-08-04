#!/bin/bash

. ./settings.sh



mongo_ver="3.2"


sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
sudo cp $REPO_PKG/mongo/mongodb-org-${mongo_ver}.list /etc/apt/sources.list.d/
sudo apt-get update
sudo apt-get install -y mongodb-org
#sudo apt-get install -y mongodb-org=3.2.6 mongodb-org-server=3.2.6 mongodb-org-shell=3.2.6 mongodb-org-mongos=3.2.6 mongodb-org-tools=3.2.6

# Pin a specific version of MongoDB.
#When a newer version becomes available. To prevent unintended upgrades, pin the package.

#echo "mongodb-org hold" | sudo dpkg --set-selections
#echo "mongodb-org-server hold" | sudo dpkg --set-selections
#echo "mongodb-org-shell hold" | sudo dpkg --set-selections
#echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
#echo "mongodb-org-tools hold" | sudo dpkg --set-selections

sudo service mongod start

# Uninstall
#sudo service mongod stop
#sudo apt-get purge mmongodb-org*
#sudo rm -r /var/log/mongodb
#sudo rm -r /var/lib/mongodb
