#!/usr/bin/env bash
set -euo pipefail

HOST_ALIAS=""
ROLE="TBD"
OS_DISK=""
DATA_DISKS=""
DATA_PATH=""
OUTPUT=""

function usage() {
    cat <<'EOF'
Usage:
  collect_inventory.sh [options]

Options:
  --host-alias NAME      Planned host alias (cloud-a/backup-b/offsite-c).
  --role ROLE            Planned node role (default: TBD).
  --os-disk /dev/sdX     Disk intended for operating system.
  --data-disks LIST      Comma-separated data disks, e.g. /dev/sdb,/dev/sdc.
  --data-path PATH       Planned data path on this node.
  --output FILE          Write markdown report to a file (also prints to stdout).
  -h, --help             Show this help message.
EOF
}

function contains_csv_item() {
    local csv="$1"
    local item="$2"

    [[ ",${csv}," == *",${item},"* ]]
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --host-alias)
        HOST_ALIAS="$2"
        shift 2
        ;;
    --role)
        ROLE="$2"
        shift 2
        ;;
    --os-disk)
        OS_DISK="$2"
        shift 2
        ;;
    --data-disks)
        DATA_DISKS="$2"
        shift 2
        ;;
    --data-path)
        DATA_PATH="$2"
        shift 2
        ;;
    --output)
        OUTPUT="$2"
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

if [[ -z "${HOST_ALIAS}" ]]; then
    HOST_ALIAS="$(hostnamectl --static 2>/dev/null || hostname -s)"
fi

if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
fi

OS_NAME="${PRETTY_NAME:-unknown}"
CPU_MODEL="$(lscpu | awk -F: '/Model name/ {sub(/^[[:space:]]+/, "", $2); print $2; exit}')"
CPU_CORES="$(nproc --all)"
RAM_GB="$(awk '/MemTotal/ {printf "%.1f", $2/1024/1024}' /proc/meminfo)"
SYSTEM_SERIAL="$(cat /sys/class/dmi/id/product_serial 2>/dev/null || true)"

TMP_FILE="$(mktemp)"
trap 'rm -f "${TMP_FILE}"' EXIT

{
    echo "## Inventory Snapshot: ${HOST_ALIAS}"
    echo
    echo "- Captured: $(date -Iseconds)"
    echo "- Hostname: $(hostnamectl --static 2>/dev/null || hostname -s)"
    echo "- Planned role: ${ROLE}"
    echo "- Planned data path: ${DATA_PATH:-TBD}"
    echo "- OS disk: ${OS_DISK:-TBD}"
    echo "- Data disk(s): ${DATA_DISKS:-TBD}"
    echo "- OS: ${OS_NAME}"
    echo "- CPU: ${CPU_MODEL:-unknown} (${CPU_CORES} cores)"
    echo "- RAM: ${RAM_GB} GiB"
    echo "- System serial: ${SYSTEM_SERIAL:-unknown}"
    echo
    echo "| Device | Size | Model | Serial | Planned use |"
    echo "|---|---|---|---|---|"

    while read -r name size type serial; do
        [[ "${type}" == "disk" ]] || continue
        device="/dev/${name}"
        model="$(tr -s ' ' <"/sys/block/${name}/device/model" 2>/dev/null | sed 's/^ //;s/ $//')"
        planned_use="unassigned"

        if [[ -n "${OS_DISK}" && "${device}" == "${OS_DISK}" ]]; then
            planned_use="OS"
        elif [[ -n "${DATA_DISKS}" ]] && contains_csv_item "${DATA_DISKS}" "${device}"; then
            planned_use="DATA"
        fi

        echo "| ${device} | ${size} | ${model:-unknown} | ${serial:-unknown} | ${planned_use} |"
    done < <(lsblk -dn -o NAME,SIZE,TYPE,SERIAL)
} >"${TMP_FILE}"

cat "${TMP_FILE}"

if [[ -n "${OUTPUT}" ]]; then
    install -D -m 0644 "${TMP_FILE}" "${OUTPUT}"
fi
