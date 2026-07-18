#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="${REPO_ROOT}/bin/mac/mac_static_ip.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/mac-static-ip-test.XXXXXX")"
trap 'rm -rf "${TEST_ROOT}"' EXIT

mkdir -p "${TEST_ROOT}/bin" "${TEST_ROOT}/home"

cat > "${TEST_ROOT}/bin/uname" <<'EOF'
#!/usr/bin/env bash

case "${1:-}" in
    -m) printf 'x86_64\n' ;;
    -r) printf 'test-kernel\n' ;;
    *) printf 'Darwin\n' ;;
esac
EOF

cat > "${TEST_ROOT}/bin/networksetup" <<'EOF'
#!/usr/bin/env bash

case "${1:-}" in
    -listallnetworkservices)
        printf 'An asterisk (*) denotes that a network service is disabled.\n'
        printf 'Wi-Fi\n'
        ;;
    -getinfo)
        printf 'DHCP Configuration\n'
        printf 'IP address: 192.168.1.10\n'
        printf 'Subnet mask: 255.255.255.0\n'
        printf 'Router: 192.168.1.1\n'
        ;;
    -getdnsservers)
        printf '1.1.1.1\n'
        printf '8.8.8.8\n'
        ;;
    *)
        printf 'unexpected networksetup arguments: %s\n' "$*" >&2
        exit 1
        ;;
esac
EOF

chmod +x "${TEST_ROOT}/bin/uname" "${TEST_ROOT}/bin/networksetup"

OUTPUT="$(PATH="${TEST_ROOT}/bin:${PATH}" HOME="${TEST_ROOT}/home" bash "${SCRIPT_PATH}" status 2>&1)" || {
    printf '%s\n' "${OUTPUT}"
    exit 1
}

assert_contains() {
    local expected="$1"

    if ! grep -F "${expected}" <<< "${OUTPUT}" >/dev/null; then
        printf 'Expected output to contain: %s\n\n%s\n' "${expected}" "${OUTPUT}" >&2
        exit 1
    fi
}

assert_contains 'Network service: Wi-Fi'
assert_contains 'IP address: 192.168.1.10'
assert_contains '25%-50% range: 192.168.1.64 - 192.168.1.127'
assert_contains '75%-100% range: 192.168.1.191 - 192.168.1.254'
assert_contains '1.1.1.1'
assert_contains '8.8.8.8'

COMMAND_LINE="$(grep -F 'Command: mac_static_ip.sh set ' <<< "${OUTPUT}" || true)"
if [ -z "${COMMAND_LINE}" ]; then
    printf 'Expected a copyable mac_static_ip.sh set command.\n\n%s\n' "${OUTPUT}" >&2
    exit 1
fi

SUGGESTED_IP="$(awk '{print $4}' <<< "${COMMAND_LINE}")"
if ! [[ "${SUGGESTED_IP}" =~ ^192\.168\.1\.[0-9]+$ ]]; then
    printf 'Expected a 192.168.1.x suggested address, got: %s\n' "${SUGGESTED_IP}" >&2
    exit 1
fi

HOST_OCTET="${SUGGESTED_IP##*.}"
if ! { [ "${HOST_OCTET}" -ge 64 ] && [ "${HOST_OCTET}" -le 127 ]; } \
    && ! { [ "${HOST_OCTET}" -ge 191 ] && [ "${HOST_OCTET}" -le 254 ]; }; then
    printf 'Suggested address is outside the advertised ranges: %s\n' "${SUGGESTED_IP}" >&2
    exit 1
fi

case "${COMMAND_LINE}" in
    *'255.255.255.0 192.168.1.1 1.1.1.1 8.8.8.8') ;;
    *)
        printf 'Suggested command did not preserve subnet, router, and DNS: %s\n' "${COMMAND_LINE}" >&2
        exit 1
        ;;
esac

printf 'mac_static_ip suggestion test passed\n'
