#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/settings.sh"
# shellcheck source=./_lib_bash_plugin.sh
source "$(dirname "$0")/_lib_bash_plugin.sh"

homebrew_ver="5.0.3"

pushd "${USER_LOCAL}" || exit 1

rm -rf homebrew
mkdir homebrew && curl -L https://github.com/Homebrew/brew/archive/refs/tags/${homebrew_ver}.tar.gz | tar xz --strip 1 -C homebrew

popd || exit 1

update_bash_plugin_block "homebrew" \
    '/^# Homebrew$/d' \
    '/^# Homwbrew$/d' \
    '/^export HOMEBREW_/d' \
    '/^export SSL_CERT_FILE=.*ca-certificates/d' \
    '/^\[ -z "\${MANPATH-}" \] || export MANPATH=/d' \
    '/^export INFOPATH=.*homebrew/d' <<EOF
$("${USER_LOCAL}/homebrew/bin/brew" shellenv)
export SSL_CERT_FILE="$("${USER_LOCAL}/homebrew/bin/brew" --prefix)/etc/ca-certificates/cert.pem"
EOF

# shellcheck source=/dev/null
source "${BASH_PLUGIN}"
brew update --force
brew postinstall ca-certificates


chmod -R go-w "$(brew --prefix)/share/zsh"




