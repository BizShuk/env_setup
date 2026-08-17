#!/bin/bash

# Client side: teach this machine to reach the registry at
# "<hostname>.local:5000" — resolve the name, and trust the self-signed
# certificate. No client certificate is issued: the registry never asks one.
#
# Copy this file and _lib_mdns.sh to the client; nothing else is needed.
# On any machine that is not the registry host, --server is mandatory.
#
#   ./client-setup.sh --server ubuntu-server --scp shuk@ubuntu-server.local
#   ./client-setup.sh --server ubuntu-server --cert ./registry.crt
#   ./client-setup.sh --server ubuntu-server --fetch   # TOFU, verify the printed fingerprint
#   ./client-setup.sh                       # on the registry host itself

set -euo pipefail

# shellcheck source=./_lib_mdns.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib_mdns.sh"

mode=local
source_arg=""
server_given=0

usage() {
    sed -n '3,15p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while [ $# -gt 0 ]; do
    case "$1" in
    --server)
        [ -n "${2:-}" ] || die "--server needs the registry host's short hostname"
        mdns_set_host "$2"
        server_given=1
        shift 2
        ;;
    --cert)
        mode=file
        source_arg="${2:-}"
        [ -n "${source_arg}" ] || die "--cert needs a path"
        shift 2
        ;;
    --scp)
        mode=scp
        source_arg="${2:-}"
        [ -n "${source_arg}" ] || die "--scp needs user@host"
        shift 2
        ;;
    --fetch)
        mode=fetch
        shift
        ;;
    -h | --help) usage 0 ;;
    *) die "unknown argument: $1 (try --help)" ;;
    esac
done

require_cmd openssl

# Without --server the target defaults to this machine's own name. That is
# right on the registry host and silently wrong everywhere else: the CA would
# land in a certs.d directory no push will ever look up.
if [ "${server_given}" -eq 0 ]; then
    if [ -f "${REGISTRY_CERT}" ]; then
        log "no --server given; targeting this host (${MDNS_DOMAIN}) — \
a registry certificate is present, so this looks like the server"
    else
        die "no --server given and no local registry certificate found.
This machine is not the registry host, so the target would be its own name
(${MDNS_DOMAIN}). Re-run with: --server <registry-hostname>"
    fi
fi

# --- 1. name resolution --------------------------------------------------
# dockerd is cgo-linked, and Go routes any .local lookup through libc, so NSS
# is what decides whether "docker push" can find the host. On macOS this is
# Bonjour and always present.
if [ "$(mdns_os)" = "linux" ]; then
    if command -v apt-get >/dev/null 2>&1 &&
        ! dpkg -s libnss-mdns >/dev/null 2>&1; then
        log "installing libnss-mdns"
        sudo apt-get update -qq
        sudo apt-get install -y libnss-mdns avahi-daemon
        sudo systemctl enable --now avahi-daemon
    fi
    grep -qE '^hosts:.*mdns' /etc/nsswitch.conf ||
        warn "/etc/nsswitch.conf has no mdns source; run setup.sh on this machine too"
fi

if getent hosts "${MDNS_DOMAIN}" >/dev/null 2>&1; then
    ok "resolves: $(getent hosts "${MDNS_DOMAIN}" | head -1)"
else
    warn "${MDNS_DOMAIN} does not resolve here yet — mDNS does not cross subnets"
fi

# --- 2. obtain the certificate -------------------------------------------
staged="$(mktemp)"
trap 'rm -f "${staged}"' EXIT

case "${mode}" in
local)
    [ -f "${REGISTRY_CERT}" ] ||
        die "no certificate at ${REGISTRY_CERT}; use --cert, --scp or --fetch"
    cp "${REGISTRY_CERT}" "${staged}"
    ;;
file)
    [ -f "${source_arg}" ] || die "no such file: ${source_arg}"
    cp "${source_arg}" "${staged}"
    ;;
scp)
    require_cmd scp
    log "fetching ${source_arg}:~/${REGISTRY_CERT_RELPATH}"
    scp -q "${source_arg}:${REGISTRY_CERT_RELPATH}" "${staged}"
    ;;
fetch)
    # Trust on first use: the certificate arrives over the very connection it
    # is meant to authenticate. Compare the fingerprint against the server's
    # gen-cert.sh output before relying on it.
    log "fetching certificate from ${REGISTRY_HOST} (unauthenticated)"
    openssl s_client -showcerts -connect "${REGISTRY_HOST}" \
        -servername "${MDNS_DOMAIN}" </dev/null 2>/dev/null |
        openssl x509 -outform PEM >"${staged}"
    [ -s "${staged}" ] || die "could not retrieve a certificate from ${REGISTRY_HOST}"
    warn "verify this against the server before trusting it:"
    warn "  SHA-256 $(mdns_cert_fingerprint "${staged}")"
    ;;
esac

openssl x509 -in "${staged}" -noout >/dev/null 2>&1 ||
    die "staged file is not a PEM certificate"

# A certificate without the name in its SANs will be rejected by dockerd no
# matter where it is installed — catch that here rather than at push time.
if ! openssl x509 -in "${staged}" -noout -ext subjectAltName 2>/dev/null |
    grep -q "DNS:${MDNS_DOMAIN}"; then
    die "certificate has no SAN for ${MDNS_DOMAIN}; regenerate with gen-cert.sh"
fi

# --- 3. install into the trust store -------------------------------------
if [ "$(mdns_os)" = "darwin" ]; then
    # Docker Desktop runs dockerd inside a VM, so /etc/docker/certs.d on the
    # host is never read; the System keychain is what it imports.
    log "adding to the System keychain (Docker Desktop reads it on restart)"
    sudo security add-trusted-cert -d -r trustRoot \
        -k /Library/Keychains/System.keychain "${staged}"
    ok "installed; restart Docker Desktop to pick it up"
else
    log "installing ${DOCKER_CERTS_D}/ca.crt"
    sudo mkdir -p "${DOCKER_CERTS_D}"
    sudo cp "${staged}" "${DOCKER_CERTS_D}/ca.crt"
    sudo chmod 0644 "${DOCKER_CERTS_D}/ca.crt"
    ok "installed; dockerd re-reads this per connection — no restart needed"
fi

ok "SHA-256 $(mdns_cert_fingerprint "${staged}")"

printf '\n'
log "verify with: ./verify.sh"
