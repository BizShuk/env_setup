#!/bin/bash

# Generate the registry's self-signed TLS certificate into
# ~/.config/registry/certs/. The certificate is its own CA, which is why the
# same file is what clients drop in as ca.crt.
#
#   ./gen-cert.sh           # no-op if a valid certificate already exists
#   ./gen-cert.sh --force   # regenerate (every client must re-run client-setup.sh)

set -euo pipefail

# shellcheck source=./_lib_mdns.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib_mdns.sh"

DAYS=3650
force=0

usage() {
    sed -n '3,8p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while [ $# -gt 0 ]; do
    case "$1" in
    -f | --force)
        force=1
        shift
        ;;
    -h | --help) usage 0 ;;
    *) die "unknown argument: $1 (try --help)" ;;
    esac
done

mdns_assert_valid_hostname
require_cmd openssl

cert_has_san() {
    openssl x509 -in "${REGISTRY_CERT}" -noout -ext subjectAltName 2>/dev/null |
        grep -q "DNS:$1"
}

if [ -f "${REGISTRY_CERT}" ] && [ "${force}" -eq 0 ]; then
    if ! cert_has_san "${REGISTRY_ALIAS_DOMAIN}"; then
        warn "existing certificate has no SAN for ${REGISTRY_ALIAS_DOMAIN}; regenerating"
    elif openssl x509 -in "${REGISTRY_CERT}" -noout -checkend 0 >/dev/null 2>&1; then
        ok "certificate exists and is valid until \
$(openssl x509 -in "${REGISTRY_CERT}" -noout -enddate | cut -d= -f2)"
        ok "SHA-256 $(mdns_cert_fingerprint "${REGISTRY_CERT}")"
        log "use --force to regenerate"
        exit 0
    else
        warn "existing certificate has expired; regenerating"
    fi
fi

# Go rejects a certificate that carries only a CN since 1.15, so every name a
# client might type has to be an explicit SAN entry. IPs are included so the
# registry stays reachable from networks mDNS does not cover (Tailscale, or a
# client with no nss-mdns).
sans=("DNS:${MDNS_DOMAIN}" "DNS:${MDNS_HOSTNAME}" "DNS:${REGISTRY_ALIAS_DOMAIN}" "DNS:localhost")
while read -r addr; do
    [ -n "${addr}" ] && sans+=("IP:${addr}")
done < <(mdns_lan_ipv4)
sans+=("IP:127.0.0.1")

log "hostname : ${MDNS_DOMAIN}"
log "alias    : ${REGISTRY_ALIAS_DOMAIN}"
log "SAN      : $(
    IFS=,
    echo "${sans[*]}"
)"

mkdir -p "${REGISTRY_CERT_DIR}"
chmod 0750 "${REGISTRY_CERT_DIR}"

openssl req -x509 -newkey rsa:4096 -sha256 -days "${DAYS}" -nodes \
    -keyout "${REGISTRY_KEY}" \
    -out "${REGISTRY_CERT}" \
    -subj "/CN=${MDNS_DOMAIN}" \
    -addext "subjectAltName=$(
        IFS=,
        echo "${sans[*]}"
    )" \
    -addext "basicConstraints=critical,CA:TRUE" \
    -addext "keyUsage=critical,digitalSignature,keyEncipherment,keyCertSign" \
    -addext "extendedKeyUsage=serverAuth" 2>/dev/null

# The container runs as this user; the key must not be world-readable, and
# 0640 keeps it readable through the read-only /certs bind mount.
chmod 0640 "${REGISTRY_KEY}"
chmod 0644 "${REGISTRY_CERT}"

ok "wrote ${REGISTRY_CERT}"
ok "wrote ${REGISTRY_KEY}"
ok "expires $(openssl x509 -in "${REGISTRY_CERT}" -noout -enddate | cut -d= -f2)"
ok "SHA-256 $(mdns_cert_fingerprint "${REGISTRY_CERT}")"

printf '\n'
log "next on this host : ./client-setup.sh"
log "next on the server: cd ~/projects/platform/cloud && ./run.sh && docker compose up -d registry"
