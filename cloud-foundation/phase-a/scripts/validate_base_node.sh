#!/usr/bin/env bash
set -euo pipefail

EXPECTED_HOSTNAME=""
FAILURES=0

function usage() {
    cat <<'EOF'
Usage:
  validate_base_node.sh [--expected-hostname cloud-a]
EOF
}

function pass() {
    echo "[PASS] $1"
}

function fail() {
    echo "[FAIL] $1"
    FAILURES=$((FAILURES + 1))
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --expected-hostname)
        EXPECTED_HOSTNAME="$2"
        shift 2
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "Unknown argument: $1" >&2
        usage
        exit 1
        ;;
    esac
done

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
fi

if [[ "${ID:-}" == "debian" && "${VERSION_ID:-}" == "12" ]]; then
    pass "OS is Debian 12"
elif [[ "${ID:-}" == "ubuntu" ]] && [[ "${VERSION_ID:-}" =~ ^(22\.04|24\.04) ]]; then
    pass "OS is Ubuntu LTS (${VERSION_ID})"
else
    fail "OS is not Debian 12 or Ubuntu LTS (found: ${PRETTY_NAME:-unknown})"
fi

if systemctl is-active --quiet ssh || systemctl is-active --quiet sshd; then
    pass "SSH service is active"
else
    fail "SSH service is not active"
fi

CURRENT_HOSTNAME="$(hostnamectl --static 2>/dev/null || hostname -s)"
if [[ -n "${EXPECTED_HOSTNAME}" ]]; then
    if [[ "${CURRENT_HOSTNAME}" == "${EXPECTED_HOSTNAME}" ]]; then
        pass "Hostname matches expected (${EXPECTED_HOSTNAME})"
    else
        fail "Hostname mismatch: expected ${EXPECTED_HOSTNAME}, got ${CURRENT_HOSTNAME}"
    fi
else
    pass "Hostname is set (${CURRENT_HOSTNAME})"
fi

if timedatectl show -p NTPSynchronized --value 2>/dev/null | grep -qx "yes"; then
    pass "Time sync reports NTPSynchronized=yes"
else
    fail "Time sync not healthy (timedatectl NTPSynchronized!=yes)"
fi

echo
echo "Interface/IP/MAC for DHCP reservation records:"
if ip -o -4 addr show scope global >/dev/null 2>&1; then
    while read -r _ iface _ cidr _; do
        ip_addr="${cidr%/*}"
        mac_addr="$(ip link show "${iface}" | awk '/link\/ether/ {print $2; exit}')"
        echo "- ${iface}: IP=${ip_addr}, MAC=${mac_addr:-unknown}"
    done < <(ip -o -4 addr show scope global)
else
    echo "- Unable to read interface info"
fi

echo
if [[ "${FAILURES}" -gt 0 ]]; then
    echo "Validation failed with ${FAILURES} issue(s)."
    exit 1
fi

echo "Validation passed."
