#!/bin/bash


source settings.sh


pushd $project_dir
    git clone https://github.com/bizshuk/bizshuk.github.io 
    git cloe https://github.com/bizshuk/static
    git clone https://github.com/bizshuk/code_sandbox 
popd


pushd $idir/server
    ln -s $idir/project/bizshuk.github.io $idir/server/ 
    ln -s $idir/project/static $idir/server/ 
popd





