#!/bin/bash



### printf container ip
docker ps -q | docker inspect -f '{{.Config.Hostname}} - {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq)