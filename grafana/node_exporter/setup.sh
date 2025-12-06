#!/bin/bash

. ~/settings.sh


# data: /var/lib/node_exporter
# bin: /usr/local/bin/node_exporter
# systemd: /e




VERSION=1.10.2
OS=$(uname | tr '[:upper:]' '[:lower:]')
ARCH=amd64
name="node_exporter-${VERSION}.${OS}-${ARCH}"
wget https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/${name}.tar.gz
tar xvfz ${name}.tar.gz

cp ${name}/node_exporter /usr/local/bin/

echo "Execute node_exporter and access localhost:9100/metrics"

# check whether node_exporter.service exists in /etc/systemd/system/
if [ ! -f /etc/systemd/system/node_exporter.service ]; then
    sudo cp ./node_exporter.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable node_exporter.service
    sudo systemctl start node_exporter.service
fi

rm -r ${name}.tar.gz