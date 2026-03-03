#!/usr/bin/env bash
set -euo pipefail

ADMIN_USER=""
PUBKEY_FILE=""
TAILSCALE_INTERFACE="tailscale0"
SSH_SOURCE_CIDR=""

function usage() {
    cat <<'EOF'
Usage:
  harden_baseline.sh --admin-user USER --pubkey-file /path/key.pub [options]

Options:
  --admin-user USER       Admin username to create/configure.
  --pubkey-file FILE      Public key file to install for admin user.
  --tailscale-interface   Tailscale interface name (default: tailscale0).
  --ssh-source-cidr CIDR  Restrict SSH to CIDR instead of allowing from anywhere.
  -h, --help              Show this help message.
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
    --admin-user)
        ADMIN_USER="$2"
        shift 2
        ;;
    --pubkey-file)
        PUBKEY_FILE="$2"
        shift 2
        ;;
    --tailscale-interface)
        TAILSCALE_INTERFACE="$2"
        shift 2
        ;;
    --ssh-source-cidr)
        SSH_SOURCE_CIDR="$2"
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

if [[ -z "${ADMIN_USER}" || -z "${PUBKEY_FILE}" ]]; then
    echo "--admin-user and --pubkey-file are required." >&2
    usage
    exit 1
fi

if [[ ! -f "${PUBKEY_FILE}" ]]; then
    echo "Public key file not found: ${PUBKEY_FILE}" >&2
    exit 1
fi

echo "Installing security baseline packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y sudo openssh-server ufw unattended-upgrades apt-listchanges

if ! id -u "${ADMIN_USER}" >/dev/null 2>&1; then
    echo "Creating admin user ${ADMIN_USER}..."
    useradd -m -s /bin/bash "${ADMIN_USER}"
fi

usermod -aG sudo "${ADMIN_USER}"

admin_home="$(getent passwd "${ADMIN_USER}" | cut -d: -f6)"
ssh_dir="${admin_home}/.ssh"
auth_file="${ssh_dir}/authorized_keys"
pubkey_content="$(tr -d '\r' <"${PUBKEY_FILE}")"

install -d -m 0700 -o "${ADMIN_USER}" -g "${ADMIN_USER}" "${ssh_dir}"
touch "${auth_file}"
chown "${ADMIN_USER}:${ADMIN_USER}" "${auth_file}"
chmod 0600 "${auth_file}"

if ! grep -Fxq "${pubkey_content}" "${auth_file}"; then
    echo "${pubkey_content}" >>"${auth_file}"
fi

echo "Configuring SSH hardening..."
cat <<'EOF' >/etc/ssh/sshd_config.d/99-phase-a-hardening.conf
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
PermitRootLogin prohibit-password
EOF

sshd -t
systemctl restart ssh 2>/dev/null || systemctl restart sshd

echo "Configuring firewall (UFW)..."
ufw default deny incoming
ufw default allow outgoing

if [[ -n "${SSH_SOURCE_CIDR}" ]]; then
    ufw allow from "${SSH_SOURCE_CIDR}" to any port 22 proto tcp
else
    ufw allow 22/tcp
fi

if ip link show "${TAILSCALE_INTERFACE}" >/dev/null 2>&1; then
    ufw allow in on "${TAILSCALE_INTERFACE}"
    ufw allow out on "${TAILSCALE_INTERFACE}"
else
    # Fallback for pre-Tailscale stage: permit traffic from Tailscale CGNAT range.
    ufw allow from 100.64.0.0/10
fi
ufw --force enable

echo "Configuring unattended security updates..."
cat <<'EOF' >/etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

systemctl enable --now unattended-upgrades

echo "Baseline hardening complete."
