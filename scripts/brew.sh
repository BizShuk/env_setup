#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/settings.sh"
# shellcheck source=./_lib_bash_plugin.sh
source "$(dirname "$0")/_lib_bash_plugin.sh"

homebrew_ver="5.0.3"
if [ "${OS}" = "darwin" ] && [ "${CPU_ARCH}" = "arm64" ]; then
    homebrew_dir="/opt/homebrew"
else
    homebrew_dir="${USER_LOCAL}/homebrew"
fi
cert_file="${homebrew_dir}/etc/ca-certificates/cert.pem"
libarchive_pkgconfig="${homebrew_dir}/opt/libarchive/lib/pkgconfig"

# The inherited SSL_CERT_FILE may point at a cert.pem that does not exist yet;
# keep it unset until ca-certificates is installed, or curl exits 77.
unset SSL_CERT_FILE

# Never delete an existing install: that wipes every installed formula in Cellar/.
if [ -x "${homebrew_dir}/bin/brew" ]; then
    echo "Homebrew already installed at ${homebrew_dir}, skipping download"
else
    if [ ! -d "${homebrew_dir}" ]; then
        if ! mkdir -p "${homebrew_dir}" 2>/dev/null; then
            brew_group="$(id -gn)"
            [ "${OS}" = "darwin" ] && brew_group="admin"
            sudo mkdir -p "${homebrew_dir}"
            sudo chown -R "$(id -un):${brew_group}" "${homebrew_dir}"
        fi
    elif [ ! -w "${homebrew_dir}" ]; then
        brew_group="$(id -gn)"
        [ "${OS}" = "darwin" ] && brew_group="admin"
        sudo chown -R "$(id -un):${brew_group}" "${homebrew_dir}"
    fi
    curl -fL "https://github.com/Homebrew/brew/archive/refs/tags/${homebrew_ver}.tar.gz" | tar xz --strip 1 -C "${homebrew_dir}"
fi

# Append Homebrew bin/sbin to PATH instead of prepending so it never shadows
# managed toolchains (e.g., ~/.local/go<ver>/bin, ~/bin, nvm) in ~/.bash_plugin.
brew_shellenv="$(SHELL=/bin/bash "${homebrew_dir}/bin/brew" shellenv | sed "s|export PATH=\"${homebrew_dir}/bin:${homebrew_dir}/sbin\${PATH+:\\\$PATH}\"|export PATH=\"\${PATH:+\$PATH:}${homebrew_dir}/bin:${homebrew_dir}/sbin\"|")"

update_bash_plugin_block "homebrew" \
    '/^# Homebrew$/d' \
    '/^# Homwbrew$/d' \
    '/^export HOMEBREW_/d' \
    '/^export PATH=.*homebrew\/bin/d' \
    '/^export SSL_CERT_FILE=.*ca-certificates/d' \
    '/^export PKG_CONFIG_PATH=.*libarchive/d' \
    '/^\[ -z "\${MANPATH-}" \] || export MANPATH=/d' \
    '/^export INFOPATH=.*homebrew/d' <<EOF
${brew_shellenv}
if [ -s "${cert_file}" ]; then export SSL_CERT_FILE="${cert_file}"; fi
if [ -d "${libarchive_pkgconfig}" ]; then case ":\${PKG_CONFIG_PATH:-}:" in *":${libarchive_pkgconfig}:"*) ;; *) export PKG_CONFIG_PATH="${libarchive_pkgconfig}\${PKG_CONFIG_PATH:+:\$PKG_CONFIG_PATH}" ;; esac; fi
EOF

# Load the target Homebrew environment directly so inherited HOMEBREW_* / PATH
# from an older prefix (e.g., ~/.local/homebrew) cannot shadow homebrew_dir.
eval "$("${homebrew_dir}/bin/brew" shellenv)"
brew update --force

# postinstall on a formula that is not installed fails with FormulaUnavailableError
if brew list --versions ca-certificates >/dev/null; then
    brew postinstall ca-certificates
else
    brew install ca-certificates
fi

if [ ! -s "${cert_file}" ]; then
    echo "ERROR: ${cert_file} missing after ca-certificates setup" >&2
    exit 1
fi
export SSL_CERT_FILE="${cert_file}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
brewfile="${script_dir}/Brewfile"
if [ "${OS}" = "darwin" ] && [ -f "${brewfile}" ]; then
    while IFS= read -r tap_name; do
        [ -n "${tap_name}" ] || continue
        brew tap "${tap_name}"
        if brew command trust >/dev/null 2>&1; then
            brew trust --tap "${tap_name}"
        fi
    done < <(sed -n 's/^[[:space:]]*tap[[:space:]]*"\([^"]*\)".*/\1/p' "${brewfile}")
    brew bundle --file="${brewfile}"
fi

if [ -d "${libarchive_pkgconfig}" ]; then
    case ":${PKG_CONFIG_PATH:-}:" in
        *":${libarchive_pkgconfig}:"*) ;;
        *) export PKG_CONFIG_PATH="${libarchive_pkgconfig}${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}" ;;
    esac
fi

if [ -d "$(brew --prefix)/share/zsh" ]; then
    chmod -R go-w "$(brew --prefix)/share/zsh"
fi

# Clean up legacy user-local Homebrew once the active prefix (e.g., /opt/homebrew) is verified.
legacy_homebrew_dir="${USER_LOCAL}/homebrew"
if [ "${homebrew_dir}" != "${legacy_homebrew_dir}" ] && [ -e "${legacy_homebrew_dir}" ] && [ -x "${homebrew_dir}/bin/brew" ]; then
    echo "Removing legacy Homebrew at ${legacy_homebrew_dir}..."
    rm -rf "${legacy_homebrew_dir}"
fi




