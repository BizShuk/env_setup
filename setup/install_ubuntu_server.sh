#!/bin/bash
source settings.sh

./setup_ubuntu_package.sh
./setup_bash_env.sh

# activate service
service ssh start;


