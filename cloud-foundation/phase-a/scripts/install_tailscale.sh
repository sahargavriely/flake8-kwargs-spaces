#!/usr/bin/env bash
set -euo pipefail

HOSTNAME_OVERRIDE=""
ACCEPT_ROUTES="false"
ENABLE_TAILSCALE_SSH="true"
TS_AUTHKEY="${TS_AUTHKEY:-}"

function usage() {
    cat <<'EOF'
Usage:
  install_tailscale.sh [options]

Options:
  --hostname NAME       Set Tailscale hostname.
  --accept-routes       Accept subnet routes from tailnet.
  --disable-ssh         Do not enable Tailscale SSH.
  --authkey KEY         Auth key (can also use TS_AUTHKEY env var).
  -h, --help            Show this help message.
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
    --hostname)
        HOSTNAME_OVERRIDE="$2"
        shift 2
        ;;
    --accept-routes)
        ACCEPT_ROUTES="true"
        shift
        ;;
    --disable-ssh)
        ENABLE_TAILSCALE_SSH="false"
        shift
        ;;
    --authkey)
        TS_AUTHKEY="$2"
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

if ! command -v tailscale >/dev/null 2>&1; then
    echo "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
else
    echo "Tailscale already installed."
fi

systemctl enable --now tailscaled

up_args=()
if [[ -n "${TS_AUTHKEY}" ]]; then
    up_args+=(--authkey "${TS_AUTHKEY}")
fi
if [[ -n "${HOSTNAME_OVERRIDE}" ]]; then
    up_args+=(--hostname "${HOSTNAME_OVERRIDE}")
fi
if [[ "${ACCEPT_ROUTES}" == "true" ]]; then
    up_args+=(--accept-routes=true)
fi
if [[ "${ENABLE_TAILSCALE_SSH}" == "true" ]]; then
    up_args+=(--ssh)
fi

if [[ "${#up_args[@]}" -gt 0 ]]; then
    echo "Running tailscale up with requested settings..."
    tailscale up "${up_args[@]}"
else
    if tailscale status >/dev/null 2>&1; then
        echo "Node already connected to a tailnet."
    else
        echo "Node is not connected yet. Run 'sudo tailscale up' and complete login."
    fi
fi

echo
echo "Tailscale IPv4:"
tailscale ip -4 || true

echo
echo "Tailscale status:"
tailscale status || true
