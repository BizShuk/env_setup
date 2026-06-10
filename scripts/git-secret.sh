#! /bin/bash
set -euo pipefail

source "$(dirname "$0")/settings.sh"

tmpdir=$(mktemp -d)

pushd "$tmpdir" || exit 1

git clone https://github.com/sobolevn/git-secret.git git-secret
cd git-secret || exit 1
make build
PREFIX=$HOME make install

popd || exit 1

rm -rf "$tmpdir"
