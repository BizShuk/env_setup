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

# Service alias, independent of which box hosts the registry. Published by
# avahi from /etc/avahi/hosts (setup.sh), so it survives a hostname change and
# lets clients pin "docker-registry.local" instead of a machine name.
MDNS_REGISTRY_ALIAS="${MDNS_REGISTRY_ALIAS:-docker-registry}"
REGISTRY_ALIAS_DOMAIN="${MDNS_REGISTRY_ALIAS}.local"
REGISTRY_ALIAS_HOST="${REGISTRY_ALIAS_DOMAIN}:${REGISTRY_PORT}"

# --- paths ---------------------------------------------------------------
# Registry runtime state follows the platform/cloud convention: one
# ~/.config/<app_name>/ per application, bind-mounted into the container.
REGISTRY_CONFIG_DIR="${HOME}/.config/registry"
REGISTRY_CERT_DIR="${REGISTRY_CONFIG_DIR}/certs"
REGISTRY_CERT="${REGISTRY_CERT_DIR}/registry.crt"
REGISTRY_KEY="${REGISTRY_CERT_DIR}/registry.key"

# Same location expressed relative to a home directory. scp resolves remote
# paths in the remote user's home, so this is what must cross the wire — the
# absolute form above is the *client's* home and would be wrong the moment the
# two machines differ (a mac client would ask for /Users/... on a Linux host).
REGISTRY_CERT_RELPATH=".config/registry/certs/registry.crt"

# Docker reads this drop-in per connection, so deploying a CA here needs no
# daemon restart. The ":${REGISTRY_PORT}" suffix is part of the directory
# name — Docker looks up "<host>:<port>", not "<host>".
DOCKER_CERTS_D="/etc/docker/certs.d/${REGISTRY_HOST}"
DOCKER_CERTS_D_ALIAS="/etc/docker/certs.d/${REGISTRY_ALIAS_HOST}"

export MDNS_HOSTNAME MDNS_DOMAIN REGISTRY_PORT REGISTRY_HOST
export MDNS_REGISTRY_ALIAS REGISTRY_ALIAS_DOMAIN REGISTRY_ALIAS_HOST DOCKER_CERTS_D_ALIAS
export REGISTRY_CONFIG_DIR REGISTRY_CERT_DIR REGISTRY_CERT REGISTRY_KEY
export REGISTRY_CERT_RELPATH
export DOCKER_CERTS_D

# The IPv4 address avahi should publish for the alias: the given interface's
# address, or the first LAN address when no interface is pinned.
mdns_publish_ipv4() {
    local iface="${1:-}"
    if [ -n "${iface}" ]; then
        ip -4 -o addr show dev "${iface}" scope global 2>/dev/null |
            awk '{ split($4, a, "/"); print a[1]; exit }'
    else
        mdns_lan_ipv4 | head -1
    fi
}

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

# Guard for every script that talks *to* the registry. Called with 1 when the
# caller passed --server, 0 otherwise.
#
# The default target is this machine's own name, which is right only on the
# registry host. Two ways it goes wrong on a client, and the second one is why
# this refuses rather than warns: macOS with no hostname set reports its
# reverse-DNS name, so `hostname -s` yields "192" out of "192.168.1.173" and
# every check then runs against "192.local" — a target that looks plausible in
# the output and cannot possibly work.
mdns_require_server() {
    [ "$1" -eq 1 ] && return 0
    [ -f "${REGISTRY_CERT}" ] && return 0

    die "no --server given and no local registry certificate found.
This machine is not the registry host, so the target defaulted to its own
name (${MDNS_DOMAIN}). Re-run with: --server <registry-hostname>"
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

# Resolve a name to IPv4 addresses, one per line; empty output means no answer.
# macOS has no getent, so the Linux form silently "fails to resolve" there even
# when the name is fine. Both branches go through the system resolver, which is
# the same path dockerd takes.
mdns_resolve_ipv4() {
    local name="$1" out=""
    if [ "$(mdns_os)" = "darwin" ]; then
        out="$(dscacheutil -q host -a name "${name}" 2>/dev/null |
            awk '/^ip_address:/ { print $2 }')"
        # dscacheutil does not always consult mDNSResponder for .local; ping
        # goes through getaddrinfo, which does.
        if [ -z "${out}" ]; then
            out="$(ping -c 1 -t 1 "${name}" 2>/dev/null |
                sed -n '1s/.*(\([0-9.]*\)).*/\1/p')"
        fi
    else
        out="$(getent ahostsv4 "${name}" 2>/dev/null | awk '{ print $1 }')"
    fi
    printf '%s\n' "${out}" | grep -E '^[0-9]+(\.[0-9]+){3}$' | sort -u || true
}
