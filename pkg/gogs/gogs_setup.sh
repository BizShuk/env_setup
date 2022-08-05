#!/bin/bash

source settings.sh

which go
if [ "$?" != "0" ]; then
    ./go_setup.sh
fi

gogs_path="$USER_PROJECT/go_project/src/github.com/gogits/gogs"

go get github.com/gogits/gogs
pushd $gogs_path
    go build
popd

echo append gogs path...
echo "# gogs" >> $INSTALL_DIR/.bash_plugin
echo "PATH=$gogs_path:\$PATH" >> $INSTALL_DIR/.bash_plugin


# config
mkdir -p $gogs_path/custom/conf
ln -sf $REPO_DIR/pkg/gogs/conf/app.ini $gogs_path/custom/conf/
