#!/usr/bin/env bash
set -euo pipefail

DATA_DISKS=""
POOL="ncdata"
DATASET="nextcloud"
MOUNTPOINT="/srv/nextcloud/data"
WIPE_CONFIRMATION=""

function usage() {
    cat <<'EOF'
Usage:
  setup_node_a_storage.sh --data-disks /dev/sdb,/dev/sdc [options]

Options:
  --data-disks LIST         Comma-separated data disks to use.
  --pool NAME               ZFS pool name (default: ncdata).
  --dataset NAME            Dataset name under pool (default: nextcloud).
  --mountpoint PATH         Dataset mountpoint (default: /srv/nextcloud/data).
  --wipe-confirmation TEXT  Required for new pool creation: I_UNDERSTAND
  -h, --help                Show this help message.
EOF
}

function require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "Please run as root (sudo)." >&2
        exit 1
    fi
}

function ensure_package() {
    local pkg="$1"
    if ! dpkg -s "${pkg}" >/dev/null 2>&1; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkg}"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --data-disks)
        DATA_DISKS="$2"
        shift 2
        ;;
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
    --wipe-confirmation)
        WIPE_CONFIRMATION="$2"
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

require_root

if [[ -z "${DATA_DISKS}" ]]; then
    echo "--data-disks is required." >&2
    usage
    exit 1
fi

IFS=',' read -r -a disks <<<"${DATA_DISKS}"
if [[ "${#disks[@]}" -lt 1 ]]; then
    echo "No valid disks parsed from --data-disks." >&2
    exit 1
fi

for disk in "${disks[@]}"; do
    if [[ ! -b "${disk}" ]]; then
        echo "Disk not found: ${disk}" >&2
        exit 1
    fi
done

ensure_package zfsutils-linux

if ! zpool list -H "${POOL}" >/dev/null 2>&1; then
    if [[ "${WIPE_CONFIRMATION}" != "I_UNDERSTAND" ]]; then
        echo "Refusing to create a new pool without --wipe-confirmation I_UNDERSTAND" >&2
        exit 1
    fi

    if [[ "${#disks[@]}" -ge 2 ]]; then
        echo "Creating mirrored ZFS pool ${POOL}..."
        zpool create -f \
            -o ashift=12 \
            -O compression=lz4 \
            -O atime=off \
            -O xattr=sa \
            -O acltype=posixacl \
            "${POOL}" mirror "${disks[0]}" "${disks[1]}"
    else
        echo "Only one data disk provided; creating a non-mirrored pool."
        zpool create -f \
            -o ashift=12 \
            -O compression=lz4 \
            -O atime=off \
            -O xattr=sa \
            -O acltype=posixacl \
            "${POOL}" "${disks[0]}"
    fi
else
    echo "ZFS pool ${POOL} already exists."
fi

dataset_full="${POOL}/${DATASET}"
if ! zfs list -H "${dataset_full}" >/dev/null 2>&1; then
    zfs create -o mountpoint="${MOUNTPOINT}" "${dataset_full}"
else
    zfs set mountpoint="${MOUNTPOINT}" "${dataset_full}"
    zfs mount "${dataset_full}" || true
fi

mkdir -p "${MOUNTPOINT}"
marker="${MOUNTPOINT}/.phase-a-storage-marker"
echo "phase-a marker $(date -Iseconds)" >"${marker}"
sync

echo
echo "Current pool status:"
zpool status "${POOL}"
echo
echo "Datasets:"
zfs list -o name,mountpoint,used,avail "${dataset_full}"
echo
echo "Storage setup complete. Marker file created at ${marker}."
