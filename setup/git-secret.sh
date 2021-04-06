#! /bin/bash

source ./settings.sh

tmpdir=$(mktemp -d)

pushd $tmpdir

git clone https://github.com/sobolevn/git-secret.git git-secret
cd git-secret && make build
PREFIX=$HOME make install

popd

rm -rf $tmpdir
