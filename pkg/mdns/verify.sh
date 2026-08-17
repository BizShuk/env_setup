#!/bin/bash

# End-to-end check: name resolution, TLS trust, and a real push/pull round
# trip. Builds a two-layer image FROM scratch so it needs no upstream pull.
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

log "target ${REGISTRY_HOST}"

# --- 1. resolution -------------------------------------------------------
# "It resolves" is not the assertion worth making. systemd-resolved synthesises
# the local hostname to every address the machine owns — including the Docker
# bridges — so this host answers even with mDNS switched off everywhere, while
# no other machine on the LAN can resolve the name at all. What matters is
# whether a LAN-routable IPv4 comes back.
if addrs="$(getent ahostsv4 "${MDNS_DOMAIN}" 2>/dev/null | awk '{print $1}' | sort -u)"; then
    ok "NSS resolves ${MDNS_DOMAIN}"
else
    warn "FAIL ${MDNS_DOMAIN} does not resolve"
    failed=1
    addrs=""
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

# --- 2. TLS --------------------------------------------------------------
ca=""
if [ -f "${DOCKER_CERTS_D}/ca.crt" ]; then
    ca="${DOCKER_CERTS_D}/ca.crt"
    ok "trust store ${ca}"
elif [ -f "${REGISTRY_CERT}" ]; then
    # curl trusts whatever we hand it, so this proves the certificate is valid
    # for the name — but says nothing about whether docker trusts it.
    ca="${REGISTRY_CERT}"
    warn "no ${DOCKER_CERTS_D}/ca.crt; falling back to ${REGISTRY_CERT} — \
this verifies the certificate, NOT that docker trusts it. Run client-setup.sh."
    degraded=1
else
    warn "FAIL no CA certificate found; run client-setup.sh"
    failed=1
fi

if [ -n "${ca}" ]; then
    check "registry API /v2/ answers over TLS" \
        curl -fsS --cacert "${ca}" "https://${REGISTRY_HOST}/v2/"
fi

# --- 3. round trip -------------------------------------------------------
# The API check above uses curl's own trust; only docker exercises the
# certs.d path, the mDNS lookup inside dockerd, and the storage backend.
if [ "${do_push}" -eq 1 ]; then
    require_cmd docker
    tmp="$(mktemp -d)"
    trap 'rm -rf "${tmp}"' EXIT

    tag="${REGISTRY_HOST}/mdns-verify:probe"
    printf 'mdns registry probe\n' >"${tmp}/probe.txt"
    printf 'FROM scratch\nCOPY probe.txt /\n' >"${tmp}/Dockerfile"

    check "build probe image" docker build -q -t "${tag}" "${tmp}"
    check "push ${tag}" docker push "${tag}"
    check "drop local copy" docker rmi -f "${tag}"
    check "pull it back" docker pull "${tag}"
    docker rmi -f "${tag}" >/dev/null 2>&1 || true

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
