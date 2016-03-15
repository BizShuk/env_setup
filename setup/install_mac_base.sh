#!/bin/bash
source settings.sh

./bash_env.sh

# run .profiler only in Mac
ln -sf $idir/.bashrc $idir/.profile
