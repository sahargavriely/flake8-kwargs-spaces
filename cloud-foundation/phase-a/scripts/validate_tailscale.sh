#!/usr/bin/env bash
set -euo pipefail

EXPECT_HOSTS=""
SKIP_PING="false"
FAILURES=0

function usage() {
    cat <<'EOF'
Usage:
  validate_tailscale.sh [options]

Options:
  --expect-hosts LIST   Comma-separated hostnames expected in tailnet.
  --skip-ping           Skip tailscale ping checks.
  -h, --help            Show this help message.
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
    --expect-hosts)
        EXPECT_HOSTS="$2"
        shift 2
        ;;
    --skip-ping)
        SKIP_PING="true"
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

if ! command -v tailscale >/dev/null 2>&1; then
    echo "[FAIL] tailscale command not found"
    exit 1
fi

if tailscale status >/dev/null 2>&1; then
    pass "tailscale status command succeeded"
else
    fail "tailscale status command failed (node may not be connected)"
fi

local_ip="$(tailscale ip -4 2>/dev/null | awk 'NR==1 {print; exit}')"
if [[ -n "${local_ip}" ]]; then
    pass "Node has Tailscale IPv4 address (${local_ip})"
else
    fail "No Tailscale IPv4 address found"
fi

status_output="$(tailscale status 2>/dev/null || true)"
local_host="$(hostnamectl --static 2>/dev/null || hostname -s)"
if [[ -n "${EXPECT_HOSTS}" ]]; then
    IFS=',' read -r -a hosts <<<"${EXPECT_HOSTS}"
    for host in "${hosts[@]}"; do
        if echo "${status_output}" | grep -Eq "([[:space:]])${host}([[:space:]]|$|\\.)"; then
            pass "Tailnet includes ${host}"
        else
            fail "Tailnet does not list ${host}"
        fi

        if [[ "${SKIP_PING}" == "false" ]]; then
            if [[ "${host%%.*}" == "${local_host}" ]]; then
                pass "Skipping ping to local host ${host}"
                continue
            fi

            if tailscale ping -c 2 "${host}" >/dev/null 2>&1; then
                pass "tailscale ping succeeded for ${host}"
            else
                fail "tailscale ping failed for ${host}"
            fi
        fi
    done
fi

echo
if [[ "${FAILURES}" -gt 0 ]]; then
    echo "Tailscale validation failed with ${FAILURES} issue(s)."
    exit 1
fi

echo "Tailscale validation passed."
