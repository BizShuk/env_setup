#!/bin/bash
source settings.sh

./ubuntu_package.sh
./ubuntu_locale.sh
./bash_env.sh
./go_setup.sh


cp /usr/share/zoneinfo/Asia/Taipei /etc/localtime


# activate service
service ssh start;


