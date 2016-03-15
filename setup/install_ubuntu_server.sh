#!/bin/bash
source settings.sh

./ubuntu_package.sh
./ubuntu_locale.sh
./bash_env.sh
./go_installation.sh

# activate service
service ssh start;


