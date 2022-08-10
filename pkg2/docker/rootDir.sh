#!/bin/bash

### stop docker
sudo service docker stop

script_path=`dirname $0`
DOCKER_CONFIG_PATH="/etc/docker/daemon.json"
DOCKER_DATA="/home/shuk/project_config/docker-data"

### Replace placeholder and put daemon.json into docker config path
cat $script_path/rootDir.json | sed "s|\[DOCKER_DATA_PATH\]|${DOCKER_DATA}|g" > ${DOCKER_CONFIG_PATH}

if test $? != 0
then
    printf "failed to update docker config\n\n"
    exit 1
fi

echo Updated Successfully at ${DOCKER_CONFIG_PATH}, content below

cat ${DOCKER_CONFIG_PATH}

### start docker
sudo service docker start


