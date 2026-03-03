#!/usr/bin/env bash
set -euo pipefail

UPS_NAME="homeups"
UPS_DRIVER="usbhid-ups"
UPS_PORT="auto"
UPS_MONITOR_USER="upsmon"
UPS_MONITOR_PASSWORD=""
SMART_ALERT_TARGET="root"

function usage() {
    cat <<'EOF'
Usage:
  setup_reliability.sh [options]

Options:
  --ups-name NAME              UPS name (default: homeups).
  --ups-driver DRIVER          NUT driver (default: usbhid-ups).
  --ups-port PORT              NUT UPS port (default: auto).
  --ups-monitor-user USER      NUT monitor user (default: upsmon).
  --ups-monitor-password PASS  NUT monitor password (required).
  --smart-alert-target EMAIL   SMART alert target (default: root).
  -h, --help                   Show this help message.
EOF
}

function require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "Please run as root (sudo)." >&2
        exit 1
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --ups-name)
        UPS_NAME="$2"
        shift 2
        ;;
    --ups-driver)
        UPS_DRIVER="$2"
        shift 2
        ;;
    --ups-port)
        UPS_PORT="$2"
        shift 2
        ;;
    --ups-monitor-user)
        UPS_MONITOR_USER="$2"
        shift 2
        ;;
    --ups-monitor-password)
        UPS_MONITOR_PASSWORD="$2"
        shift 2
        ;;
    --smart-alert-target)
        SMART_ALERT_TARGET="$2"
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

if [[ -z "${UPS_MONITOR_PASSWORD}" ]]; then
    echo "--ups-monitor-password is required." >&2
    usage
    exit 1
fi

echo "Installing smartmontools + NUT..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y smartmontools nut

echo "Configuring SMART monitoring..."
cat <<EOF >/etc/smartd.conf
DEVICESCAN -a -o on -S on -m ${SMART_ALERT_TARGET}
EOF

if systemctl enable --now smartd >/dev/null 2>&1; then
    SMART_SERVICE="smartd"
elif systemctl enable --now smartmontools >/dev/null 2>&1; then
    SMART_SERVICE="smartmontools"
else
    echo "Unable to start smartd/smartmontools service." >&2
    exit 1
fi

echo "Configuring NUT (standalone)..."
cat <<'EOF' >/etc/nut/nut.conf
MODE=standalone
EOF

cat <<EOF >/etc/nut/ups.conf
[${UPS_NAME}]
  driver = ${UPS_DRIVER}
  port = ${UPS_PORT}
  desc = "Node A UPS"
EOF

cat <<EOF >/etc/nut/upsd.users
[${UPS_MONITOR_USER}]
  password = ${UPS_MONITOR_PASSWORD}
  upsmon primary
EOF

cat <<EOF >/etc/nut/upsmon.conf
RUN_AS_USER root
MONITOR ${UPS_NAME}@localhost 1 ${UPS_MONITOR_USER} ${UPS_MONITOR_PASSWORD} primary
MINSUPPLIES 1
SHUTDOWNCMD "/sbin/shutdown -h +0"
POLLFREQ 5
POLLFREQALERT 5
HOSTSYNC 15
DEADTIME 15
POWERDOWNFLAG /etc/killpower
FINALDELAY 5
EOF

chmod 0640 /etc/nut/upsd.users /etc/nut/upsmon.conf

for service in nut-server nut-monitor nut-client; do
    systemctl enable --now "${service}" >/dev/null 2>&1 || true
done

echo
echo "SMART service status:"
systemctl --no-pager --full status "${SMART_SERVICE}" | sed -n '1,8p' || true
echo
echo "UPS readout (if attached):"
upsc "${UPS_NAME}@localhost" || true
echo
echo "Reliability setup complete."
