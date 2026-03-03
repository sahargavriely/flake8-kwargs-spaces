#!/usr/bin/env bash
set -euo pipefail

POOL="ncdata"
DATASET="nextcloud"
MOUNTPOINT="/srv/nextcloud/data"
EXPECT_MIRROR="false"
MODE="check"
FAILURES=0

function usage() {
    cat <<'EOF'
Usage:
  validate_storage.sh [options]

Options:
  --pool NAME          ZFS pool name (default: ncdata).
  --dataset NAME       Dataset name (default: nextcloud).
  --mountpoint PATH    Mountpoint path (default: /srv/nextcloud/data).
  --expect-mirror      Require mirror vdev presence in pool status.
  --mode MODE          check | prepare-reboot | post-reboot (default: check).
  -h, --help           Show this help message.
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
    --pool)
        POOL="$2"
        shift 2
        ;;
    --dataset)
        DATASET="$2"
        shift 2
        ;;
    --mountpoint)
        MOUNTPOINT="$2"
        shift 2
        ;;
    --expect-mirror)
        EXPECT_MIRROR="true"
        shift
        ;;
    --mode)
        MODE="$2"
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

dataset_full="${POOL}/${DATASET}"
marker="${MOUNTPOINT}/.phase-a-storage-marker"

if zpool list -H "${POOL}" >/dev/null 2>&1; then
    pass "ZFS pool ${POOL} exists"
else
    fail "ZFS pool ${POOL} not found"
fi

pool_status="$(zpool status "${POOL}" 2>/dev/null || true)"
if echo "${pool_status}" | grep -q "state: ONLINE"; then
    pass "Pool ${POOL} is ONLINE"
else
    fail "Pool ${POOL} is not ONLINE"
fi

if [[ "${EXPECT_MIRROR}" == "true" ]]; then
    if echo "${pool_status}" | grep -q "mirror-"; then
        pass "Pool ${POOL} contains mirror vdev"
    else
        fail "Pool ${POOL} does not show mirror vdev"
    fi
fi

if zfs list -H "${dataset_full}" >/dev/null 2>&1; then
    pass "Dataset ${dataset_full} exists"
else
    fail "Dataset ${dataset_full} does not exist"
fi

if findmnt -n --target "${MOUNTPOINT}" >/dev/null 2>&1; then
    pass "Mountpoint ${MOUNTPOINT} is mounted"
else
    fail "Mountpoint ${MOUNTPOINT} is not mounted"
fi

case "${MODE}" in
check)
    :
    ;;
prepare-reboot)
    echo "phase-a reboot marker $(date -Iseconds)" >"${marker}"
    sync
    pass "Created reboot persistence marker at ${marker}"
    ;;
post-reboot)
    if [[ -f "${marker}" ]]; then
        pass "Reboot persistence marker still exists (${marker})"
    else
        fail "Reboot persistence marker missing (${marker})"
    fi
    ;;
*)
    echo "Invalid mode: ${MODE}" >&2
    usage
    exit 1
    ;;
esac

echo
if [[ "${FAILURES}" -gt 0 ]]; then
    echo "Storage validation failed with ${FAILURES} issue(s)."
    exit 1
fi

echo "Storage validation passed."
