#!/bin/bash

. settings.sh

git submodule init
git submodule update


if [ "$os" == "darwin" ]; then
    . ./mac_setup.sh
elif [ "$os" == "linux" ]; then
    . ./ubuntu_setup.sh
else
    echo No Matched OS.
fi

. ./bash_env_setup.sh
. ./go_setup.sh

