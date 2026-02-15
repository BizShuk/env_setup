#!/bin/bash

. ~/settings.sh


docker pull prom/pushgateway:v1.11.2
docker run --name pushgateway -d -p 9091:9091 prom/pushgateway:v1.11.2

sudo cp -f ./push_gateway.service ${SYSTEMD_DIR}/


sudo systemctl enable push_gateway.service
sudo systemctl start push_gateway.service