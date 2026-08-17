#!/bin/bash

# Server side: publish this host as "<hostname>.local" over mDNS and make the
# local resolver able to answer .local queries.
#
# Idempotent: safe to re-run. Requires sudo for apt and /etc edits.
#
#   ./setup.sh                  # publish on every interface
#   ./setup.sh --interface enp3s0   # publish on one interface only

set -euo pipefail

# shellcheck source=./_lib_mdns.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_lib_mdns.sh"

AVAHI_CONF=/etc/avahi/avahi-daemon.conf
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

# --- 4. daemon ---------------------------------------------------------
log "enabling avahi-daemon"
sudo systemctl enable --now avahi-daemon
sudo systemctl reload-or-restart avahi-daemon
systemctl is-active --quiet avahi-daemon ||
    die "avahi-daemon failed to start; see: journalctl -u avahi-daemon -n 50"
ok "avahi-daemon active"

# --- 5. self-check -------------------------------------------------------
# avahi-resolve proves the record is published; getent proves NSS is wired up.
# They fail independently, so both are worth asserting.
if avahi-resolve -n "${MDNS_DOMAIN}" >/dev/null 2>&1; then
    ok "published: $(avahi-resolve -n "${MDNS_DOMAIN}")"
else
    warn "avahi-resolve could not find ${MDNS_DOMAIN} yet (announce takes a few seconds)"
fi

if getent hosts "${MDNS_DOMAIN}" >/dev/null 2>&1; then
    ok "resolvable via NSS: $(getent hosts "${MDNS_DOMAIN}" | head -1)"
else
    die "getent cannot resolve ${MDNS_DOMAIN}; NSS is not using mdns"
fi

printf '\n'
log "domain ready: ${MDNS_DOMAIN}"
log "next: ./gen-cert.sh"
