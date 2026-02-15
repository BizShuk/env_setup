#!/bin/bash

. ~/settings.sh

# data: /var/lib/prometheus
# config: /etc/local/prometheus
# bin: /usr/local/bin/prometheus
# systemd: /etc/systemd/system/prometheus.service


VERSION="3.8.0"
name="prometheus-${VERSION}.${os}-${ARCH}"


wget https://github.com/prometheus/prometheus/releases/download/v${VERSION}/${name}.tar.gz
tar xvfz ${name}.tar.gz


sudo cp ${name}/* /usr/local/bin/
sudo ln -s $(pwd)/prometheus.yml /etc/local/
sudo mkdir -p /var/lib/prometheus

echo "Execute node_exporter and access localhost:9100/metrics"

# check whether prometheus.service exists in /etc/systemd/system/
if [ ! -f /etc/systemd/system/prometheus.service ]; then
    sudo cp -f ./prometheus.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable prometheus.service
    sudo systemctl start prometheus.service
fi

rm -r ${name}.tar.gz