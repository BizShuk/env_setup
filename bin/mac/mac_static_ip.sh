#!/usr/bin/env bash

# Configure or inspect a static IPv4 address for a macOS network service.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../bash/settings.sh
source "${SCRIPT_DIR}/../bash/settings.sh"

DEFAULT_SERVICE="Wi-Fi"

usage() {
    cat <<'EOF'
Usage:
  mac_static_ip.sh status [service]
  mac_static_ip.sh services
  mac_static_ip.sh set [service] <ip> <subnet-mask> <router> [dns ...] [--yes]
  mac_static_ip.sh dhcp [service] [--yes]

Examples:
  mac_static_ip.sh status
  mac_static_ip.sh set 192.168.1.100 255.255.255.0 192.168.1.1 1.1.1.1 8.8.8.8
  mac_static_ip.sh set Ethernet 192.168.1.101 255.255.255.0 192.168.1.1 --yes
  mac_static_ip.sh dhcp Wi-Fi

The default service is Wi-Fi. If DNS is omitted, the router address is used.
Use a DHCP reservation on the router when possible to prevent IP conflicts.
EOF
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

require_macos() {
    [ "${OS}" = "darwin" ] || die "this command only supports macOS"
    command -v networksetup >/dev/null 2>&1 || die "networksetup was not found"
}

is_ipv4() {
    local address="$1"
    local octets=()
    local octet

    IFS='.' read -r -a octets <<< "${address}"
    [ "${#octets[@]}" -eq 4 ] || return 1

    for octet in "${octets[@]}"; do
        [[ "${octet}" =~ ^[0-9]+$ ]] || return 1
        [ "$((10#${octet}))" -le 255 ] || return 1
    done
}

is_subnet_mask() {
    case "$1" in
        0.0.0.0|128.0.0.0|192.0.0.0|224.0.0.0|240.0.0.0|248.0.0.0|252.0.0.0|254.0.0.0|255.0.0.0|\
        255.128.0.0|255.192.0.0|255.224.0.0|255.240.0.0|255.248.0.0|255.252.0.0|255.254.0.0|255.255.0.0|\
        255.255.128.0|255.255.192.0|255.255.224.0|255.255.240.0|255.255.248.0|255.255.252.0|255.255.254.0|255.255.255.0|\
        255.255.255.128|255.255.255.192|255.255.255.224|255.255.255.240|255.255.255.248|255.255.255.252|255.255.255.254|255.255.255.255)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

list_services() {
    networksetup -listallnetworkservices
}

service_exists() {
    local requested="$1"
    local service

    while IFS= read -r service; do
        service="${service#\*}"
        [ "${service}" = "${requested}" ] && return 0
    done < <(networksetup -listallnetworkservices | tail -n +2)

    return 1
}

require_service() {
    service_exists "$1" || {
        printf 'Available services:\n' >&2
        list_services >&2
        die "network service '$1' was not found"
    }
}

show_status() {
    local service="$1"

    require_service "${service}"
    printf 'Network service: %s\n' "${service}"
    networksetup -getinfo "${service}"
    printf 'DNS servers:\n'
    networksetup -getdnsservers "${service}"
}

confirm_change() {
    local assume_yes="$1"
    local answer

    [ "${assume_yes}" = "true" ] && return 0
    printf 'Apply this network change? [y/N] '
    if ! IFS= read -r answer; then
        printf '\n' >&2
        die "confirmation input was unavailable; pass --yes for non-interactive use"
    fi
    case "${answer}" in
        y|Y|yes|YES) return 0 ;;
        *) die "cancelled" ;;
    esac
}

set_static_ip() {
    local service="$1"
    local ip="$2"
    local subnet="$3"
    local router="$4"
    shift 4

    local assume_yes="false"
    local dns=()
    local value

    for value in "$@"; do
        if [ "${value}" = "--yes" ]; then
            assume_yes="true"
        else
            is_ipv4 "${value}" || die "invalid DNS IPv4 address: ${value}"
            dns+=("${value}")
        fi
    done

    require_service "${service}"
    is_ipv4 "${ip}" || die "invalid IPv4 address: ${ip}"
    is_subnet_mask "${subnet}" || die "invalid or non-contiguous subnet mask: ${subnet}"
    is_ipv4 "${router}" || die "invalid router IPv4 address: ${router}"
    [ "${#dns[@]}" -gt 0 ] || dns=("${router}")

    printf 'Static IPv4 configuration:\n'
    printf '  Service: %s\n' "${service}"
    printf '  Address: %s\n' "${ip}"
    printf '  Subnet:  %s\n' "${subnet}"
    printf '  Router:  %s\n' "${router}"
    printf '  DNS:     %s\n' "${dns[*]}"
    printf '\nConfirm that the address is unused or reserved on your router.\n'
    confirm_change "${assume_yes}"

    sudo -v
    sudo networksetup -setmanual "${service}" "${ip}" "${subnet}" "${router}"
    sudo networksetup -setdnsservers "${service}" "${dns[@]}"

    printf '\nStatic IPv4 configuration applied.\n'
    show_status "${service}"
}

restore_dhcp() {
    local service="$1"
    local assume_yes="$2"

    require_service "${service}"
    printf 'Restore DHCP and automatic DNS for: %s\n' "${service}"
    confirm_change "${assume_yes}"

    sudo -v
    sudo networksetup -setdhcp "${service}"
    sudo networksetup -setdnsservers "${service}" Empty

    printf '\nDHCP and automatic DNS restored.\n'
    show_status "${service}"
}

main() {
    require_macos

    local command="${1:-status}"
    [ "$#" -eq 0 ] || shift

    case "${command}" in
        status)
            [ "$#" -le 1 ] || die "status accepts at most one service name"
            show_status "${1:-${DEFAULT_SERVICE}}"
            ;;
        services)
            [ "$#" -eq 0 ] || die "services does not accept arguments"
            list_services
            ;;
        set)
            if [ "$#" -ge 3 ] && is_ipv4 "$1"; then
                set_static_ip "${DEFAULT_SERVICE}" "$@"
            elif [ "$#" -ge 4 ]; then
                local service="$1"
                shift
                set_static_ip "${service}" "$@"
            else
                usage
                exit 1
            fi
            ;;
        dhcp)
            local service="${DEFAULT_SERVICE}"
            local assume_yes="false"
            local service_set="false"
            local value
            for value in "$@"; do
                if [ "${value}" = "--yes" ]; then
                    assume_yes="true"
                elif [ "${service_set}" = "false" ]; then
                    service="${value}"
                    service_set="true"
                else
                    die "dhcp accepts at most one service name and --yes"
                fi
            done
            restore_dhcp "${service}" "${assume_yes}"
            ;;
        -h|--help|help)
            usage
            ;;
        *)
            usage
            die "unknown command: ${command}"
            ;;
    esac
}

main "$@"
