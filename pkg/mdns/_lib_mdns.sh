#!/bin/bash

# Shared variables and helpers for pkg/mdns/ scripts.
# Source only; never execute directly.
#
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib_mdns.sh"
#
# Deliberately does NOT source bin/bash/settings.sh: client-setup.sh must stay
# copyable to a machine that has no env_setup checkout. Nothing here needs
# REPO_DIR, so the dependency would buy nothing and cost portability.

# --- identity ------------------------------------------------------------
# Hostname is the domain. Avahi publishes "$(hostname -s).local" out of the
# box, so no extra alias record has to be maintained.
MDNS_HOSTNAME="${MDNS_HOSTNAME:-$(hostname -s)}"
MDNS_DOMAIN="${MDNS_HOSTNAME}.local"

REGISTRY_PORT="${REGISTRY_PORT:-5000}"
REGISTRY_HOST="${MDNS_DOMAIN}:${REGISTRY_PORT}"

# --- paths ---------------------------------------------------------------
# Registry runtime state follows the platform/cloud convention: one
# ~/.config/<app_name>/ per application, bind-mounted into the container.
REGISTRY_CONFIG_DIR="${HOME}/.config/registry"
REGISTRY_CERT_DIR="${REGISTRY_CONFIG_DIR}/certs"
REGISTRY_CERT="${REGISTRY_CERT_DIR}/registry.crt"
REGISTRY_KEY="${REGISTRY_CERT_DIR}/registry.key"

# Docker reads this drop-in per connection, so deploying a CA here needs no
# daemon restart. The ":${REGISTRY_PORT}" suffix is part of the directory
# name — Docker looks up "<host>:<port>", not "<host>".
DOCKER_CERTS_D="/etc/docker/certs.d/${REGISTRY_HOST}"

export MDNS_HOSTNAME MDNS_DOMAIN REGISTRY_PORT REGISTRY_HOST
export REGISTRY_CONFIG_DIR REGISTRY_CERT_DIR REGISTRY_CERT REGISTRY_KEY
export DOCKER_CERTS_D

# Re-point every derived value at another host. The defaults above describe
# "the registry is this machine", which is only true on the server; a client
# must name the server explicitly or it would trust a certificate for its own
# hostname and then fail to resolve anything.
mdns_set_host() {
    MDNS_HOSTNAME="$1"
    MDNS_DOMAIN="${MDNS_HOSTNAME}.local"
    REGISTRY_HOST="${MDNS_DOMAIN}:${REGISTRY_PORT}"
    DOCKER_CERTS_D="/etc/docker/certs.d/${REGISTRY_HOST}"
    export MDNS_HOSTNAME MDNS_DOMAIN REGISTRY_HOST DOCKER_CERTS_D
}

# --- output --------------------------------------------------------------
log() { printf '\033[0;36m==>\033[0m %s\n' "$*"; }
ok() { printf '\033[0;32m ok\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m  !\033[0m %s\n' "$*" >&2; }
die() {
    printf '\033[0;31mERR\033[0m %s\n' "$*" >&2
    exit 1
}

require_cmd() {
    local cmd
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 ||
            die "required command not found: ${cmd}"
    done
}

# --- platform ------------------------------------------------------------
mdns_os() { uname | tr '[:upper:]' '[:lower:]'; }

mdns_require_linux() {
    [ "$(mdns_os)" = "linux" ] ||
        die "$1 targets Linux; macOS resolves .local through built-in Bonjour"
}

# A DNS label may not contain "_" or "."; avahi silently mangles such names.
mdns_assert_valid_hostname() {
    case "${MDNS_HOSTNAME}" in
    *[!a-zA-Z0-9-]* | -* | *-)
        die "hostname '${MDNS_HOSTNAME}' is not a valid DNS label; \
rename the host or override with MDNS_HOSTNAME=<label>"
        ;;
    esac
}

# Global-scope IPv4 addresses that belong to the host itself, excluding the
# bridges Docker manages — those change per compose project and would pin a
# 10-year certificate to a throwaway subnet.
mdns_lan_ipv4() {
    ip -4 -o addr show scope global 2>/dev/null |
        awk '$2 !~ /^(docker|br-|veth|virbr)/ { split($4, a, "/"); print a[1] }'
}

mdns_cert_fingerprint() {
    openssl x509 -in "$1" -noout -fingerprint -sha256 | cut -d= -f2
}
