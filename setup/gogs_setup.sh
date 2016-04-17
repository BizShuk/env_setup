#!/bin/bash

source settings.sh

which go
if [ "$?" != "0" ]; then
    ./go_setup.sh
fi

gogs_path="$idir/project/go_project/src/github.com/gogits/gogs"

go get github.com/gogits/gogs
pushd $gogs_path
    go build
popd

echo append gogs path...
echo "# gogs" >> $idir/.bash_plugin
echo "PATH=$gogs_path:\$PATH" >> $idir/bash_plugin
