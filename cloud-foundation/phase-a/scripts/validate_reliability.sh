#!/usr/bin/env bash
set -euo pipefail

UPS_NAME="homeups"
RUN_FSD_TEST="false"
FAILURES=0

function usage() {
    cat <<'EOF'
Usage:
  validate_reliability.sh [options]

Options:
  --ups-name NAME     UPS name configured in NUT (default: homeups).
  --run-fsd-test      Trigger upsmon forced-shutdown simulation.
  -h, --help          Show this help message.
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
    --ups-name)
        UPS_NAME="$2"
        shift 2
        ;;
    --run-fsd-test)
        RUN_FSD_TEST="true"
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

if systemctl is-active --quiet smartd || systemctl is-active --quiet smartmontools; then
    pass "SMART monitoring service is active"
else
    fail "SMART monitoring service is not active"
fi

while read -r disk; do
    [[ -n "${disk}" ]] || continue
    health_output="$(smartctl -H "${disk}" 2>/dev/null || true)"
    if echo "${health_output}" | grep -Eq "PASSED|OK"; then
        pass "SMART health looks good for ${disk}"
    else
        fail "SMART health did not report PASSED/OK for ${disk}"
    fi
done < <(lsblk -dn -o NAME,TYPE | awk '$2=="disk" {print "/dev/"$1}')

ups_output="$(upsc "${UPS_NAME}@localhost" 2>/dev/null || true)"
if [[ -n "${ups_output}" ]]; then
    pass "UPS status is readable via upsc ${UPS_NAME}@localhost"
else
    fail "UPS status is not readable via upsc ${UPS_NAME}@localhost"
fi

for field in battery.charge input.voltage ups.load; do
    if echo "${ups_output}" | grep -q "^${field}:"; then
        pass "UPS field present: ${field}"
    else
        fail "UPS field missing: ${field}"
    fi
done

if [[ "${RUN_FSD_TEST}" == "true" ]]; then
    echo
    echo "Starting simulated power-loss test (upsmon forced shutdown)..."
    echo "This can shut the node down immediately."
    sleep 3
    upsmon -c fsd
fi

echo
if [[ "${FAILURES}" -gt 0 ]]; then
    echo "Reliability validation failed with ${FAILURES} issue(s)."
    exit 1
fi

echo "Reliability validation passed."
