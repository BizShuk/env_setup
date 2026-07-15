#!/usr/bin/env bash
# 建置 macbackup (macOS 設定 backup/import) 並安裝到 ~/.local/bin (已在 PATH)。
set -euo pipefail

cd "$(dirname "$0")"

OUT="${HOME}/.local/bin/macbackup"
mkdir -p "$(dirname "$OUT")"

go build -o "$OUT" .
echo "installed -> $OUT"
