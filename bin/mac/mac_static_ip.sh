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
The status command also prints subnet-based candidate ranges and a copyable
static-IP command when the current service has a usable IPv4 configuration.
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

ipv4_to_int() {
    local address="$1"
    local octets=()

    is_ipv4 "${address}" || return 1
    IFS='.' read -r -a octets <<< "${address}"
    printf '%s\n' "$((10#${octets[0]} * 16777216 + 10#${octets[1]} * 65536 + 10#${octets[2]} * 256 + 10#${octets[3]}))"
}

int_to_ipv4() {
    local value="$1"

    printf '%d.%d.%d.%d\n' \
        "$(( (value >> 24) & 255 ))" \
        "$(( (value >> 16) & 255 ))" \
        "$(( (value >> 8) & 255 ))" \
        "$(( value & 255 ))"
}

network_bounds() {
    local ip="$1"
    local subnet="$2"
    local ip_int
    local subnet_int
    local network_int
    local broadcast_int

    ip_int="$(ipv4_to_int "${ip}")" || return 1
    subnet_int="$(ipv4_to_int "${subnet}")" || return 1
    network_int=$((ip_int & subnet_int))
    broadcast_int=$((network_int | (4294967295 ^ subnet_int)))
    printf '%s %s\n' "${network_int}" "${broadcast_int}"
}

candidate_range() {
    local network_int="$1"
    local broadcast_int="$2"
    local lower_percent="$3"
    local upper_percent="$4"
    local usable_start=$((network_int + 1))
    local usable_end=$((broadcast_int - 1))
    local usable_count=$((usable_end - usable_start + 1))
    local start_offset
    local end_offset

    [ "${usable_count}" -gt 0 ] || return 1
    start_offset=$(( (usable_count * lower_percent + 99) / 100 ))
    end_offset=$((usable_count * upper_percent / 100))
    [ "${start_offset}" -ge 1 ] || start_offset=1
    [ "${end_offset}" -le "${usable_count}" ] || end_offset="${usable_count}"
    [ "${start_offset}" -le "${end_offset}" ] || return 1

    printf '%s %s\n' \
        "$((usable_start + start_offset - 1))" \
        "$((usable_start + end_offset - 1))"
}

random_uint() {
    local maximum="$1"
    local raw

    [ "${maximum}" -gt 0 ] || return 1
    if ! raw="$(od -An -N4 -tu4 /dev/urandom | tr -d '[:space:]')"; then
        return 1
    fi
    [ -n "${raw}" ] || return 1
    printf '%s\n' "$((10#${raw} % maximum))"
}

random_between() {
    local lower="$1"
    local upper="$2"
    local width
    local offset

    [ "${lower}" -le "${upper}" ] || return 1
    width=$((upper - lower + 1))
    offset="$(random_uint "${width}")" || return 1
    printf '%s\n' "$((lower + offset))"
}

networksetup_value() {
    local label="$1"
    local info="$2"
    local line

    while IFS= read -r line; do
        case "${line}" in
            "${label}: "*)
                printf '%s\n' "${line#"${label}: "}"
                return 0
                ;;
        esac
    done <<< "${info}"

    return 1
}

extract_dns_ipv4() {
    local dns_output="$1"
    local line

    while IFS= read -r line; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        is_ipv4 "${line}" && printf '%s\n' "${line}"
    done <<< "${dns_output}"
}

show_suggestion() {
    local service="$1"
    local info="$2"
    local dns_output="$3"
    local ip
    local subnet
    local router
    local bounds
    local network_int
    local broadcast_int
    local first_range
    local second_range
    local first_start_int
    local first_end_int
    local second_start_int
    local second_end_int
    local selected_start_int
    local selected_end_int
    local selected_int
    local selected_band
    local first_start_ip
    local first_end_ip
    local second_start_ip
    local second_end_ip
    local selected_ip
    local dns
    local command
    local dns_servers=()

    if ! ip="$(networksetup_value 'IP address' "${info}")" || ! is_ipv4 "${ip}"; then
        printf '\nRecommended static IP: unavailable (current IPv4 address was not found)\n'
        return 0
    fi
    if ! subnet="$(networksetup_value 'Subnet mask' "${info}")" || ! is_subnet_mask "${subnet}"; then
        printf '\nRecommended static IP: unavailable (current subnet mask was not found or is invalid)\n'
        return 0
    fi
    if ! router="$(networksetup_value 'Router' "${info}")" || ! is_ipv4 "${router}"; then
        printf '\nRecommended static IP: unavailable (current router was not found)\n'
        return 0
    fi
    if ! bounds="$(network_bounds "${ip}" "${subnet}")"; then
        printf '\nRecommended static IP: unavailable (could not calculate the current subnet)\n'
        return 0
    fi
    read -r network_int broadcast_int <<< "${bounds}"

    if ! first_range="$(candidate_range "${network_int}" "${broadcast_int}" 25 50)" \
        || ! second_range="$(candidate_range "${network_int}" "${broadcast_int}" 75 100)"; then
        printf '\nRecommended static IP: unavailable (the subnet has no usable host range, such as /31 or /32)\n'
        return 0
    fi
    read -r first_start_int first_end_int <<< "${first_range}"
    read -r second_start_int second_end_int <<< "${second_range}"

    first_start_ip="$(int_to_ipv4 "${first_start_int}")"
    first_end_ip="$(int_to_ipv4 "${first_end_int}")"
    second_start_ip="$(int_to_ipv4 "${second_start_int}")"
    second_end_ip="$(int_to_ipv4 "${second_end_int}")"

    if ! selected_band="$(random_between 0 1)"; then
        printf '\nRecommended static IP: unavailable (could not read /dev/urandom)\n'
        return 0
    fi
    if [ "${selected_band}" -eq 0 ]; then
        selected_start_int="${first_start_int}"
        selected_end_int="${first_end_int}"
    else
        selected_start_int="${second_start_int}"
        selected_end_int="${second_end_int}"
    fi
    if ! selected_int="$(random_between "${selected_start_int}" "${selected_end_int}")"; then
        printf '\nRecommended static IP: unavailable (could not select a host address)\n'
        return 0
    fi
    selected_ip="$(int_to_ipv4 "${selected_int}")"

    while IFS= read -r dns; do
        [ -n "${dns}" ] && dns_servers+=("${dns}")
    done < <(extract_dns_ipv4 "${dns_output}")
    [ "${#dns_servers[@]}" -gt 0 ] || dns_servers=("${router}")

    command='mac_static_ip.sh set'
    if [ "${service}" != "${DEFAULT_SERVICE}" ]; then
        command="${command} $(printf '%q' "${service}")"
    fi
    command="${command} ${selected_ip} ${subnet} ${router}"
    for dns in "${dns_servers[@]}"; do
        command="${command} ${dns}"
    done

    printf '\nRecommended static IP:\n'
    printf '  25%%-50%% range: %s - %s\n' "${first_start_ip}" "${first_end_ip}"
    printf '  75%%-100%% range: %s - %s\n' "${second_start_ip}" "${second_end_ip}"
    printf '  Selected address: %s\n' "${selected_ip}"
    printf '  Command: %s\n' "${command}"
    printf '  Note: confirm the address is unused, preferably reserve it outside the router DHCP pool.\n'
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
    local info
    local dns_output

    require_service "${service}"
    printf 'Network service: %s\n' "${service}"
    info="$(networksetup -getinfo "${service}")"
    printf '%s\n' "${info}"
    printf 'DNS servers:\n'
    dns_output="$(networksetup -getdnsservers "${service}" 2>&1 || true)"
    printf '%s\n' "${dns_output}"
    show_suggestion "${service}" "${info}" "${dns_output}"
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

if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
    main "$@"
fi
