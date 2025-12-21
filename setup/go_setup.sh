#!/bin/bash
source settings.sh


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

GO_VER=${GO_VER:-1.23.5}
GO_FULLVER="go${GO_VER}.${os}-${GO_ARCH}"
GO_ROOT="$USER_LIB/$GO_FULLVER"    # go package dir
GO_PATH="$USER_LIB/go" # Where the go dependency/library downloaded

[ ! -d "${GO_PATH}" ] && mkdir -p "${GO_PATH}"

if [ ! -e "$USER_LIB"/"$GO_FULLVER" ]; then
    echo "$GO_FULLVER  installing..."
    wget https://go.dev/dl/"${GO_FULLVER}".tar.gz -O /tmp/"$GO_FULLVER"
    # wget https://storage.googleapis.com/golang/"${GO_FULLVER}".tar.gz -O /tmp/"$GO_FULLVER"

    tar zxf /tmp/"$GO_FULLVER" -C /tmp
    mv /tmp/go "$USER_LIB"/"$GO_FULLVER"

fi

echo -e "\n# [Go]" >> "${INSTALL_DIR}"/.bash_plugin
echo "export GOROOT=${GO_ROOT}" >>"${INSTALL_DIR}"/.bash_plugin
echo "export GOPATH=${GO_PATH}" >>"${INSTALL_DIR}"/.bash_plugin
echo "export PATH=\$GOPATH/bin:\$PATH" >>"${INSTALL_DIR}"/.bash_plugin
# echo "# [GOVCS] control which version control tool is used for go get from 1.16" >>"${INSTALL_DIR}"/.bash_plugin
# echo "export GOVCS=git" >>"${INSTALL_DIR}"/.bash_plugin


[ -L "$USER_BIN"/go ] && echo "go has already installed , now switch to $GO_FULLVER"

ln -sf "$GO_ROOT"/bin/go "$USER_BIN"/go


