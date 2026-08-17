#!/bin/bash

# Server side: publish this host as "<hostname>.local" plus the registry
# alias "docker-registry.local" over mDNS, and make the local resolver able to
# answer .local queries.
#
# Idempotent: safe to re-run. Requires sudo for apt and /etc edits.
#
#   ./setup.sh                  # publish on every interface
#   ./setup.sh --interface enp3s0   # publish on one interface only

set -euo pipefail

# shellcheck source=./_lib_mdns.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib_mdns.sh"

AVAHI_CONF=/etc/avahi/avahi-daemon.conf
AVAHI_HOSTS=/etc/avahi/hosts
NSSWITCH=/etc/nsswitch.conf
interface=""

usage() {
    sed -n '3,10p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while [ $# -gt 0 ]; do
    case "$1" in
    --interface)
        interface="${2:-}"
        [ -n "${interface}" ] || die "--interface needs an interface name"
        shift 2
        ;;
    -h | --help) usage 0 ;;
    *) die "unknown argument: $1 (try --help)" ;;
    esac
done

mdns_require_linux "setup.sh"
mdns_assert_valid_hostname
require_cmd apt-get systemctl grep sed

# --- 1. packages ---------------------------------------------------------
# avahi-daemon publishes the record; libnss-mdns is what lets *this* host
# resolve .local names. Installing only the daemon is the usual mistake: the
# registry would be visible to every other machine but not to itself.
missing=()
dpkg -s avahi-daemon >/dev/null 2>&1 || missing+=(avahi-daemon)
dpkg -s avahi-utils >/dev/null 2>&1 || missing+=(avahi-utils)
dpkg -s libnss-mdns >/dev/null 2>&1 || missing+=(libnss-mdns)

if [ ${#missing[@]} -gt 0 ]; then
    log "installing: ${missing[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y "${missing[@]}"
else
    ok "avahi-daemon, avahi-utils, libnss-mdns already installed"
fi

# --- 2. nsswitch -------------------------------------------------------
# libnss-mdns's postinst normally patches this. It skips hosts lines it does
# not recognise, so verify rather than assume.
if grep -qE '^hosts:.*mdns' "${NSSWITCH}"; then
    ok "${NSSWITCH} already routes .local through mdns"
else
    log "patching ${NSSWITCH} (backup: ${NSSWITCH}.bak)"
    sudo sed -i.bak -E \
        '/^hosts:/ s/\bdns\b/mdns4_minimal [NOTFOUND=return] dns/' \
        "${NSSWITCH}"
    grep -qE '^hosts:.*mdns' "${NSSWITCH}" ||
        die "patch failed; add 'mdns4_minimal [NOTFOUND=return]' before 'dns' \
on the hosts line of ${NSSWITCH} by hand"
fi
grep -E '^hosts:' "${NSSWITCH}"

# --- 3. interface scope ------------------------------------------------
# Two NICs on the same subnet make avahi advertise both addresses, and the
# client takes whichever answer arrives first. Pin one when that matters.
if [ -n "${interface}" ]; then
    log "restricting avahi to ${interface}"
    if grep -qE '^[#[:space:]]*allow-interfaces=' "${AVAHI_CONF}"; then
        sudo sed -i.bak -E \
            "s|^[#[:space:]]*allow-interfaces=.*|allow-interfaces=${interface}|" \
            "${AVAHI_CONF}"
    else
        sudo sed -i.bak -E \
            "/^\[server\]/a allow-interfaces=${interface}" \
            "${AVAHI_CONF}"
    fi
    grep -E '^allow-interfaces=' "${AVAHI_CONF}"
fi

# --- 4. service alias --------------------------------------------------
# avahi has no CNAME support, but /etc/avahi/hosts publishes extra A records
# natively — no avahi-publish process to keep alive. The alias must point at
# a LAN address, never a Docker bridge, so it goes through the same filter as
# the certificate SANs.
alias_ip="$(mdns_publish_ipv4 "${interface}")"
[ -n "${alias_ip}" ] ||
    die "no LAN IPv4 to publish ${REGISTRY_ALIAS_DOMAIN}${interface:+ on ${interface}}"
if grep -qE "^${alias_ip}[[:space:]]+${REGISTRY_ALIAS_DOMAIN}\$" "${AVAHI_HOSTS}"; then
    ok "${AVAHI_HOSTS} already publishes ${REGISTRY_ALIAS_DOMAIN} -> ${alias_ip}"
else
    log "publishing ${REGISTRY_ALIAS_DOMAIN} -> ${alias_ip} via ${AVAHI_HOSTS}"
    sudo sed -i.bak -E "/[[:space:]]${REGISTRY_ALIAS_DOMAIN}\$/d" "${AVAHI_HOSTS}"
    printf '%s %s\n' "${alias_ip}" "${REGISTRY_ALIAS_DOMAIN}" |
        sudo tee -a "${AVAHI_HOSTS}" >/dev/null
fi

# A leftover ad-hoc publisher for the same name (e.g. a manual `avahi-publish
# -a`) makes the static entry fail with "Local name collision" at startup, and
# the alias then silently disappears once that process exits.
pkill -f "avahi-publish -a .*${REGISTRY_ALIAS_DOMAIN}" 2>/dev/null &&
    warn "stopped a stray avahi-publish for ${REGISTRY_ALIAS_DOMAIN}"

# --- 5. daemon ---------------------------------------------------------
log "enabling avahi-daemon"
sudo systemctl enable --now avahi-daemon
# Must be restart, NOT reload-or-restart. avahi's ExecReload only re-reads the
# static service files under /etc/avahi/services/; avahi-daemon.conf is parsed
# at startup only. A reload therefore reports success while leaving the daemon
# running on the previous configuration — the package's own postinst has
# already started it by this point, so a reload here changes nothing.
sudo systemctl restart avahi-daemon
systemctl is-active --quiet avahi-daemon ||
    die "avahi-daemon failed to start; see: journalctl -u avahi-daemon -n 50"
ok "avahi-daemon active"

# --- 6. self-check -------------------------------------------------------
# avahi-resolve proves the record is published; getent proves NSS is wired up.
# They fail independently, so both are worth asserting.
published="$(avahi-resolve -n "${MDNS_DOMAIN}" 2>/dev/null | awk '{print $2}')"
if [ -n "${published}" ]; then
    ok "published: ${MDNS_DOMAIN} -> ${published}"
else
    warn "avahi-resolve could not find ${MDNS_DOMAIN} yet (announce takes a few seconds)"
fi

# Publishing a Docker bridge address is the failure that looks like success:
# the name resolves, and every client outside this box then dials an address
# only this box can reach.
case "${published}" in
172.1[6-9].* | 172.2[0-9].* | 172.3[0-1].* | 127.*)
    die "avahi is publishing ${published}, a Docker/loopback address no other \
machine can reach. Re-run with --interface <lan-nic>, e.g.:
    $0 --interface $(ip -4 -o addr show scope global |
        awk '$2 !~ /^(docker|br-|veth|virbr)/ {print $2; exit}')"
    ;;
esac

if getent hosts "${MDNS_DOMAIN}" >/dev/null 2>&1; then
    ok "resolvable via NSS: $(getent hosts "${MDNS_DOMAIN}" | head -1)"
else
    die "getent cannot resolve ${MDNS_DOMAIN}; NSS is not using mdns"
fi

# The alias has no systemd-resolved fallback: if it does not resolve here, it
# is not published at all.
alias_resolved="$(getent ahostsv4 "${REGISTRY_ALIAS_DOMAIN}" 2>/dev/null | awk '{ print $1; exit }')"
if [ "${alias_resolved}" = "${alias_ip}" ]; then
    ok "alias resolvable: ${REGISTRY_ALIAS_DOMAIN} -> ${alias_resolved}"
else
    warn "${REGISTRY_ALIAS_DOMAIN} resolves to '${alias_resolved:-nothing}' (expected ${alias_ip}); \
announce may take a few seconds — re-run ./verify.sh"
    journalctl -u avahi-daemon -n 20 --no-pager 2>/dev/null |
        grep -F "${REGISTRY_ALIAS_DOMAIN}" | tail -3 || true
fi

printf '\n'
log "domain ready: ${MDNS_DOMAIN} (alias ${REGISTRY_ALIAS_DOMAIN})"
log "next: ./gen-cert.sh"
