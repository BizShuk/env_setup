#!/usr/bin/env bash
set -euo pipefail

openssl_ver="${OPENSSL_VER:-3.0.13}"
openssl="openssl-${openssl_ver}"

# 私有 staging dir: 下載與解壓都在此進行, 不在呼叫者的工作目錄留下殘骸;
# /tmp 為 world-writable, 固定檔名會讓其他使用者有機會預先埋 symlink 或 tarball。
OPENSSL_TMP="$(mktemp -d)"
trap 'rm -rf "${OPENSSL_TMP}"' EXIT

# 用 curl 而非 wget: 部分 macOS 的 wget build 找不到 CA bundle, 會在憑證驗證處直接失敗。
# 保留 TLS 驗證: 這份 tarball 會被編譯並安裝到系統。
curl -fL --proto '=https' --tlsv1.2 \
    "https://www.openssl.org/source/${openssl}.tar.gz" \
    -o "${OPENSSL_TMP}/${openssl}.tar.gz"

tar zxf "${OPENSSL_TMP}/${openssl}.tar.gz" -C "${OPENSSL_TMP}"

pushd "${OPENSSL_TMP}/${openssl}" >/dev/null || exit 1
./config
make -j
sudo make install
popd >/dev/null || exit 1
