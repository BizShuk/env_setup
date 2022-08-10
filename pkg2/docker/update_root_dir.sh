#!/bin/bash

### stop docker
service docker stop

script_path=`dirname $0`
DOCKER_CONFIG_PATH="/etc/docker/daemon.json"
DOCKER_ROOT="/var/lib/docker"
DOCKER_ROOT_NEW="/home/shuk/project_config/docker-data"


### Replace placeholder and put daemon.json into docker config path
cp /etc/docker/daemon.json /etc/docker/daemon.json.bak # backup
sed "s|\[DOCKER_ROOT_PATH\]|${DOCKER_ROOT_NEW}|g" $script_path/daemon.json > ${DOCKER_CONFIG_PATH}

### Sync DockerRoot to new location
rsync -aP ${DOCKER_ROOT} ${DOCKER_ROOT_NEW}

if test $? != 0
then
    printf "failed to update docker config\n\n"
    exit 1
fi

echo Updated Successfully at ${DOCKER_CONFIG_PATH}, content below

cat ${DOCKER_CONFIG_PATH}

### start docker
service docker start
[ $? == "0" ] && rm -rf ${DOCKER_ROOT}

