#!/bin/bash

### Show docker0 interface
ip addr show docker0

# [How to permit access host from container](https://stackoverflow.com/a/31328031) TODO: dive deep iptable command

### printf container ip
docker ps -q | docker inspect -f '{{.Config.Hostname}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)


### prune volume
docker volume ls -f dangling=true
