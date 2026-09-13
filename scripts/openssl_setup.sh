#!/usr/bin/env bash
set -euo pipefail

openssl_ver="3.0.13"
openssl="openssl-${openssl_ver}"

# 用 curl 而非 wget: 部分 macOS 的 wget build 找不到 CA bundle, 會在憑證驗證處直接失敗。
curl -fL --proto '=https' --tlsv1.2 -O \
    "https://www.openssl.org/source/${openssl}.tar.gz"

tar zxvf ${openssl}.tar.gz

pushd $openssl || exit
    ./config
    make -j
    sudo make install
popd || exit
rm -rf ${openssl}
rm -f ${openssl}.tar.gz
