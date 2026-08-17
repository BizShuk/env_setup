#!/bin/bash

# End-to-end check: name resolution (hostname + docker-registry.local alias),
# TLS trust, and a real push/pull round trip. Builds a two-layer image FROM
# scratch so it needs no upstream pull.
#
#   ./verify.sh                              # full check including push/pull
#   ./verify.sh --no-push                    # resolution and TLS only
#   ./verify.sh --server ubuntu-server       # from a client machine

set -euo pipefail

# shellcheck source=./_lib_mdns.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib_mdns.sh"

do_push=1
failed=0
degraded=0
server_given=0

# One trap for the whole script: a second `trap ... EXIT` silently replaces the
# first, which previously leaked the temp file holding the keychain copy of the
# CA. Plain strings rather than an array — macOS still ships bash 3.2, where
# expanding an empty array under `set -u` is itself an error.
keychain_ca=""
probe_dir=""
cleanup() {
    [ -n "${keychain_ca}" ] && rm -f "${keychain_ca}"
    [ -n "${probe_dir}" ] && rm -rf "${probe_dir}"
    return 0
}
trap cleanup EXIT

usage() {
    sed -n '3,8p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while [ $# -gt 0 ]; do
    case "$1" in
    --no-push)
        do_push=0
        shift
        ;;
    --server)
        [ -n "${2:-}" ] || die "--server needs the registry host's short hostname"
        mdns_set_host "$2"
        server_given=1
        shift 2
        ;;
    -h | --help) usage 0 ;;
    *) die "unknown argument: $1 (try --help)" ;;
    esac
done

check() {
    local label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        ok "${label}"
    else
        warn "FAIL ${label}"
        failed=1
    fi
}

mdns_require_server "${server_given}"

log "target ${REGISTRY_HOST}"

# --- 1. resolution -------------------------------------------------------
# "It resolves" is not the assertion worth making. systemd-resolved synthesises
# the local hostname to every address the machine owns — including the Docker
# bridges — so this host answers even with mDNS switched off everywhere, while
# no other machine on the LAN can resolve the name at all. What matters is
# whether a LAN-routable IPv4 comes back.
addrs="$(mdns_resolve_ipv4 "${MDNS_DOMAIN}")"
if [ -n "${addrs}" ]; then
    ok "${MDNS_DOMAIN} resolves"
else
    warn "FAIL ${MDNS_DOMAIN} does not resolve"
    warn "     nothing on the LAN is publishing this name. Run setup.sh on \
the registry host (${MDNS_HOSTNAME}) — installing avahi there is what makes \
the name visible to any other machine."
    failed=1
fi

lan_addrs="$(printf '%s\n' "${addrs}" | grep -vE '^(127\.|172\.1[6-9]\.|172\.2[0-9]\.|172\.3[0-1]\.)' || true)"
bridge_addrs="$(printf '%s\n' "${addrs}" | grep -E '^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-1]\.' || true)"

[ -n "${addrs}" ] && ok "  -> $(printf '%s' "${addrs}" | tr '\n' ' ')"

if [ -n "${addrs}" ] && [ -z "${lan_addrs}" ]; then
    warn "no LAN-routable IPv4 in the answer; clients will not reach the registry"
    degraded=1
fi
if [ -n "${bridge_addrs}" ]; then
    warn "answer includes Docker bridge addresses ($(printf '%s' "${bridge_addrs}" | tr '\n' ' ')); \
a client may pick one and hang"
    degraded=1
fi
if [ "$(mdns_os)" = "linux" ] && ! grep -qE '^hosts:.*mdns' /etc/nsswitch.conf; then
    warn "/etc/nsswitch.conf has no mdns source — this host resolves the name locally, \
but no other machine on the LAN can. Run setup.sh."
    degraded=1
fi

# The alias is published from /etc/avahi/hosts only, so unlike the hostname it
# has no systemd-resolved fallback: resolving here means avahi really answered.
alias_addrs="$(mdns_resolve_ipv4 "${REGISTRY_ALIAS_DOMAIN}")"
if [ -z "${alias_addrs}" ]; then
    warn "FAIL ${REGISTRY_ALIAS_DOMAIN} does not resolve; re-run setup.sh on ${MDNS_HOSTNAME}"
    failed=1
elif [ -n "${lan_addrs}" ] && ! printf '%s\n' "${lan_addrs}" | grep -qxF "${alias_addrs}"; then
    warn "FAIL ${REGISTRY_ALIAS_DOMAIN} -> ${alias_addrs}, not one of ${MDNS_DOMAIN}'s LAN \
addresses; another host is publishing the alias, or setup.sh ran with a stale IP"
    failed=1
else
    ok "${REGISTRY_ALIAS_DOMAIN} resolves -> $(printf '%s' "${alias_addrs}" | tr '\n' ' ')"
fi

# --- 2. TLS --------------------------------------------------------------
# Where the CA lives is platform-specific, and must match what client-setup.sh
# actually did: Docker Desktop runs dockerd inside a VM and never reads the
# host's /etc/docker/certs.d, so on macOS the System keychain is the only
# answer that means anything.
ca=""
if [ "$(mdns_os)" = "darwin" ]; then
    keychain_ca="$(mktemp)"
    if security find-certificate -c "${MDNS_DOMAIN}" -p \
        /Library/Keychains/System.keychain >"${keychain_ca}" 2>/dev/null &&
        [ -s "${keychain_ca}" ]; then
        ca="${keychain_ca}"
        ok "trust store: System keychain (CN=${MDNS_DOMAIN})"
    fi
fi

if [ -n "${ca}" ]; then
    : # already resolved above
elif [ -f "${DOCKER_CERTS_D}/ca.crt" ]; then
    ca="${DOCKER_CERTS_D}/ca.crt"
    ok "trust store ${ca}"
elif [ -f "${REGISTRY_CERT}" ]; then
    # curl trusts whatever we hand it, so this proves the certificate is valid
    # for the name — but says nothing about whether docker trusts it.
    ca="${REGISTRY_CERT}"
    warn "no ${DOCKER_CERTS_D}/ca.crt; falling back to ${REGISTRY_CERT} — \
this verifies the certificate, NOT that docker trusts it. Run client-setup.sh."
    degraded=1
elif [ "$(mdns_os)" = "darwin" ]; then
    warn "FAIL no certificate for ${MDNS_DOMAIN} in the System keychain; run client-setup.sh"
    failed=1
else
    warn "FAIL no CA certificate found; run client-setup.sh"
    failed=1
fi

if [ -n "${ca}" ]; then
    # A stale trust store is the common failure after gen-cert.sh --force:
    # every TLS check fails, and nothing says why. Compare what we trust with
    # what the registry actually serves.
    served="$(openssl s_client -connect "${REGISTRY_HOST}" -servername "${MDNS_DOMAIN}" \
        </dev/null 2>/dev/null | openssl x509 -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2)"
    if [ -n "${served}" ] && [ "${served}" != "$(mdns_cert_fingerprint "${ca}")" ]; then
        warn "trust store holds a different certificate than ${REGISTRY_HOST} serves \
(server regenerated it?) — re-run client-setup.sh --server ${MDNS_HOSTNAME}"
    fi
    check "registry API /v2/ answers over TLS" \
        curl -fsS --cacert "${ca}" "https://${REGISTRY_HOST}/v2/"
    check "registry API /v2/ answers via ${REGISTRY_ALIAS_HOST}" \
        curl -fsS --cacert "${ca}" "https://${REGISTRY_ALIAS_HOST}/v2/"
fi

# --- 3. round trip -------------------------------------------------------
# The API check above uses curl's own trust; only docker exercises the
# certs.d path, the mDNS lookup inside dockerd, and the storage backend.
if [ "${do_push}" -eq 1 ]; then
    require_cmd docker
    # Without a running daemon every step below fails identically, and the
    # five FAIL lines read as a registry problem rather than a local one.
    docker info >/dev/null 2>&1 ||
        die "docker daemon is not running (docker info failed); start it and re-run"
    tmp="$(mktemp -d)"
    probe_dir="${tmp}"

    tag="${REGISTRY_HOST}/mdns-verify:probe"
    printf 'mdns registry probe\n' >"${tmp}/probe.txt"
    printf 'FROM scratch\nCOPY probe.txt /\n' >"${tmp}/Dockerfile"

    check "build probe image" docker build -q -t "${tag}" "${tmp}"
    check "push ${tag}" docker push "${tag}"
    check "drop local copy" docker rmi -f "${tag}"
    check "pull it back" docker pull "${tag}"
    docker rmi -f "${tag}" >/dev/null 2>&1 || true

    # Same repository through the alias: exercises dockerd's own lookup of the
    # alias name and its certs.d entry (or keychain) for that host:port.
    alias_tag="${REGISTRY_ALIAS_HOST}/mdns-verify:probe"
    check "pull via ${alias_tag}" docker pull "${alias_tag}"
    docker rmi -f "${alias_tag}" >/dev/null 2>&1 || true

    if [ -n "${ca}" ]; then
        check "catalog lists the repository" \
            bash -c "curl -fsS --cacert '${ca}' 'https://${REGISTRY_HOST}/v2/_catalog' | grep -q mdns-verify"
    fi
fi

printf '\n'
if [ "${failed}" -ne 0 ]; then
    die "some checks failed (see FAIL lines above)"
elif [ "${degraded}" -ne 0 ]; then
    warn "checks passed, but only because this host is a special case — \
see the warnings above before assuming other machines can reach the registry"
    exit 0
else
    ok "all checks passed"
fi
