#!/bin/bash
source "$(dirname "$0")/settings.sh"
set -euo pipefail


# Go env
GO_ARCH=""
case "${CPU_ARCH}" in
i386)
    GO_ARCH="386"
    ;;
arm64)
    GO_ARCH=${CPU_ARCH}
    ;;
*)
    GO_ARCH="amd64" # x86_64
    ;;
esac

GO_VER=${GO_VER:-1.26.6}
GO_FULLVER="go${GO_VER}.${os}-${GO_ARCH}"
GO_ROOT="$USER_LIB/$GO_FULLVER"    # go package dir
GO_PATH="$USER_LIB/go" # Where the go dependency/library downloaded

[ ! -d "${GO_PATH}" ] && mkdir -p "${GO_PATH}"

if [ ! -e "$USER_LIB"/"$GO_FULLVER" ]; then
    echo "$GO_FULLVER  installing...:" https://go.dev/dl/"${GO_FULLVER}".tar.gz
    # Private staging dir: /tmp is world-writable, so a predictable name lets any
    # local user pre-plant a symlink or a tarball of their choosing.
    GO_TMP="$(mktemp -d)"
    trap 'rm -rf "${GO_TMP}"' EXIT
    # TLS verification stays on: the tarball is executed as the toolchain.
    # 用 curl 而非 wget: 部分 macOS 的 wget build 找不到 CA bundle, 會在憑證驗證處直接失敗。
    curl -fL --proto '=https' --tlsv1.2 https://go.dev/dl/"${GO_FULLVER}".tar.gz \
        -o "${GO_TMP}"/"${GO_FULLVER}".tar.gz

    tar zxf "${GO_TMP}"/"${GO_FULLVER}".tar.gz -C "${GO_TMP}"
    mv "${GO_TMP}"/go "$USER_LIB"/"$GO_FULLVER"
fi

# .bash_plugin 的 Go 區塊以 marker 包夾, 每次重跑先刪除舊區塊再重寫,
# 避免升版後累積指向舊 GOROOT 的 export 行 (go tool 與 compile 版本不符會 build failed)。
# shellcheck source=./_lib_bash_plugin.sh
source "$(dirname "$0")/_lib_bash_plugin.sh"

update_bash_plugin_block "go" \
    '/^# \[Go\]$/d' \
    '/^export GOROOT=/d' \
    '/^export GOPATH=/d' \
    '/^export PATH=\$GOPATH\/bin:\$PATH$/d' <<EOF
# [Go] 由 scripts/go.sh 產生, 重跑會整段覆寫
export GOROOT=${GO_ROOT}
export GOPATH=${GO_PATH}
export PATH=\$GOPATH/bin:\$PATH
# [GOVCS] control which version control tool is used for go get from 1.16
# echo "export GOVCS=git"
EOF


[ -L "$USER_BIN"/go ] && echo "go has already installed , now switch to $GO_FULLVER"

ln -sf "$GO_ROOT"/bin/go "$USER_BIN"/go



# golangci linter (remove legacy v1 before installing v2+)
GOPATH_BIN="$(go env GOPATH)/bin"
if [ -x "${GOPATH_BIN}/golangci-lint" ]; then
    LINT_VER="$("${GOPATH_BIN}/golangci-lint" --version 2>/dev/null || true)"
    if ! echo "${LINT_VER}" | grep -qE "version (v)?2\."; then
        echo "Removing legacy golangci-lint (${LINT_VER})..."
        rm -f "${GOPATH_BIN}/golangci-lint"
        rm -rf "${HOME}/Library/Caches/golangci-lint" "${HOME}/.cache/golangci-lint"
    fi
fi
rm -f "${GOPATH_BIN}/golangci-lint-v2"

GOLANGCI_LINT_VER=${GOLANGCI_LINT_VER:-v2.13.2}
curl -sSfL https://golangci-lint.run/install.sh | sh -s -- -b "${GOPATH_BIN}" "${GOLANGCI_LINT_VER}"
ln -sf "${HOME}/bin/.golangci.yml" ~/
