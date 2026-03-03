#!/usr/bin/env bash
set -euo pipefail

SSH_USER="${USER}"
HOSTS="cloud-a,backup-b,offsite-c"
REQUIRE_KEY_ONLY="false"
FAILURES=0

function usage() {
    cat <<'EOF'
Usage:
  validate_from_laptop.sh [options]

Options:
  --user USER            SSH username (default: current user).
  --hosts LIST           Comma-separated hosts (default: cloud-a,backup-b,offsite-c).
  --require-key-only     Also verify key auth works and password auth fails.
  -h, --help             Show this help message.
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
    --user)
        SSH_USER="$2"
        shift 2
        ;;
    --hosts)
        HOSTS="$2"
        shift 2
        ;;
    --require-key-only)
        REQUIRE_KEY_ONLY="true"
        shift
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

IFS=',' read -r -a HOST_ARRAY <<<"${HOSTS}"

for host in "${HOST_ARRAY[@]}"; do
    target="${SSH_USER}@${host}"
    expected_hostname="${host%%.*}"

    echo
    echo "Checking ${target}..."

    if ssh -o BatchMode=yes -o ConnectTimeout=8 "${target}" "true" >/dev/null 2>&1; then
        pass "SSH reachable for ${host}"
    else
        fail "Cannot SSH to ${host}"
        continue
    fi

    remote_hostname="$(ssh -o BatchMode=yes -o ConnectTimeout=8 "${target}" "hostnamectl --static 2>/dev/null || hostname -s" 2>/dev/null || true)"
    if [[ "${remote_hostname}" == "${expected_hostname}" ]]; then
        pass "Hostname is ${remote_hostname}"
    else
        fail "Hostname mismatch on ${host} (got: ${remote_hostname:-unknown}, expected: ${expected_hostname})"
    fi

    ntp_sync="$(ssh -o BatchMode=yes -o ConnectTimeout=8 "${target}" "timedatectl show -p NTPSynchronized --value 2>/dev/null || echo no" 2>/dev/null || true)"
    if [[ "${ntp_sync}" == "yes" ]]; then
        pass "NTP sync healthy on ${host}"
    else
        fail "NTP sync not healthy on ${host}"
    fi

    if [[ "${REQUIRE_KEY_ONLY}" == "true" ]]; then
        if ssh -o BatchMode=yes -o PreferredAuthentications=publickey -o PasswordAuthentication=no -o ConnectTimeout=8 "${target}" "true" >/dev/null 2>&1; then
            pass "Key-based SSH authentication works on ${host}"
        else
            fail "Key-based SSH authentication failed on ${host}"
        fi

        if ssh -o BatchMode=yes -o PreferredAuthentications=password -o PubkeyAuthentication=no -o NumberOfPasswordPrompts=1 -o ConnectTimeout=8 "${target}" "true" >/dev/null 2>&1; then
            fail "Password authentication unexpectedly succeeded on ${host}"
        else
            pass "Password authentication is blocked on ${host}"
        fi
    fi
done

echo
if [[ "${FAILURES}" -gt 0 ]]; then
    echo "Laptop validation failed with ${FAILURES} issue(s)."
    exit 1
fi

echo "Laptop validation passed."
