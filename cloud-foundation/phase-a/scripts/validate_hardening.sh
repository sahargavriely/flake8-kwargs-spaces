#!/usr/bin/env bash
set -euo pipefail

TAILSCALE_INTERFACE="tailscale0"
FAILURES=0

function usage() {
    cat <<'EOF'
Usage:
  validate_hardening.sh [--tailscale-interface tailscale0]
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
    --tailscale-interface)
        TAILSCALE_INTERFACE="$2"
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

if sshd -T | grep -qx "passwordauthentication no"; then
    pass "SSHD PasswordAuthentication is disabled"
else
    fail "SSHD PasswordAuthentication is not disabled"
fi

if sshd -T | grep -qx "kbdinteractiveauthentication no"; then
    pass "SSHD KbdInteractiveAuthentication is disabled"
else
    fail "SSHD KbdInteractiveAuthentication is not disabled"
fi

if sshd -T | grep -qx "pubkeyauthentication yes"; then
    pass "SSHD PubkeyAuthentication is enabled"
else
    fail "SSHD PubkeyAuthentication is not enabled"
fi

if ufw status | grep -q "^Status: active"; then
    pass "UFW firewall is active"
else
    fail "UFW firewall is not active"
fi

if ufw status | grep -Eq "22/tcp|OpenSSH"; then
    pass "UFW allows SSH"
else
    fail "UFW does not show SSH allow rule"
fi

if ufw status | grep -q "${TAILSCALE_INTERFACE}"; then
    pass "UFW includes Tailscale interface rules"
elif ufw status | grep -q "100.64.0.0/10"; then
    pass "UFW includes Tailscale CGNAT fallback rule"
else
    fail "UFW missing Tailscale rule (${TAILSCALE_INTERFACE} or 100.64.0.0/10)"
fi

if systemctl is-enabled --quiet unattended-upgrades; then
    pass "Unattended upgrades service is enabled"
else
    fail "Unattended upgrades service is not enabled"
fi

if systemctl is-active --quiet unattended-upgrades; then
    pass "Unattended upgrades service is active"
else
    fail "Unattended upgrades service is not active"
fi

echo
if [[ "${FAILURES}" -gt 0 ]]; then
    echo "Hardening validation failed with ${FAILURES} issue(s)."
    exit 1
fi

echo "Hardening validation passed."
