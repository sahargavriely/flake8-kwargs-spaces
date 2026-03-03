# Self-Hosted Cloud Foundation - Phase A

This folder turns your six Phase A foundation tasks into a practical runbook
with scripts you can execute on Debian 12 or Ubuntu LTS nodes.

## Folder structure

- `inventory.md`: one-page hardware + role + storage inventory.
- `scripts/collect_inventory.sh`: gather CPU/RAM/disk/serial data from a node.
- `scripts/validate_base_node.sh`: validate hostname, SSH service, time sync.
- `scripts/validate_from_laptop.sh`: verify SSH reachability to all nodes.
- `scripts/harden_baseline.sh`: user/SSH/firewall/auto-update hardening.
- `scripts/validate_hardening.sh`: confirm hardening on each node.
- `scripts/install_tailscale.sh`: install and join Tailscale.
- `scripts/validate_tailscale.sh`: verify peer visibility and connectivity.
- `scripts/setup_node_a_storage.sh`: build Node A ZFS storage dataset.
- `scripts/validate_storage.sh`: check pool health, mount persistence marker.
- `scripts/setup_reliability.sh`: configure SMART + NUT (UPS).
- `scripts/validate_reliability.sh`: validate SMART health and UPS readings.

## Preconditions

1. Linux installed on each node (Debian 12 or Ubuntu LTS minimal).
2. SSH enabled on each node.
3. Router access for DHCP reservations.
4. Your laptop has SSH keys and can reach all nodes.
5. UPS physically connected to Node A (USB/serial as supported).

## Step 1 - Hardware and naming inventory

On each node:

```bash
sudo ./cloud-foundation/phase-a/scripts/collect_inventory.sh \
  --host-alias cloud-a \
  --role "Nextcloud primary" \
  --os-disk /dev/sda \
  --data-disks /dev/sdb,/dev/sdc \
  --data-path /srv/nextcloud/data
```

Repeat for `backup-b` and `offsite-c`, then paste outputs into
`cloud-foundation/phase-a/inventory.md`.

Validate:

- You have a one-page inventory doc.
- Each device includes planned role and storage path.

## Step 2 - Install Linux and base validation

Manual:

1. Install Debian 12 (or Ubuntu LTS) minimal on all nodes.
2. Set hostnames: `cloud-a`, `backup-b`, `offsite-c`.
3. Enable SSH.
4. Configure static DHCP reservations in your router.

On each node:

```bash
sudo ./cloud-foundation/phase-a/scripts/validate_base_node.sh --expected-hostname cloud-a
```

From your laptop:

```bash
./cloud-foundation/phase-a/scripts/validate_from_laptop.sh \
  --user admin \
  --hosts cloud-a,backup-b,offsite-c
```

Validate:

- SSH works from laptop to each node.
- `hostnamectl` hostname matches planned name.
- `timedatectl` reports synchronized time.

## Step 3 - Baseline security hardening

On each node:

```bash
sudo ./cloud-foundation/phase-a/scripts/harden_baseline.sh \
  --admin-user admin \
  --pubkey-file /tmp/admin_id_ed25519.pub
```

Then validate on each node:

```bash
sudo ./cloud-foundation/phase-a/scripts/validate_hardening.sh
```

From laptop (key-only check):

```bash
./cloud-foundation/phase-a/scripts/validate_from_laptop.sh \
  --user admin \
  --hosts cloud-a,backup-b,offsite-c \
  --require-key-only
```

Validate:

- Password-based SSH auth fails.
- Key-based SSH auth works.
- Firewall is active and allows SSH + Tailscale interface.
- Auto-security-updates service is enabled.

## Step 4 - Install and join Tailscale

On each node and each client:

```bash
sudo ./cloud-foundation/phase-a/scripts/install_tailscale.sh --hostname cloud-a
```

If you have an auth key:

```bash
sudo TS_AUTHKEY="tskey-..." ./cloud-foundation/phase-a/scripts/install_tailscale.sh --hostname cloud-a
```

Validate:

```bash
./cloud-foundation/phase-a/scripts/validate_tailscale.sh --expect-hosts cloud-a,backup-b,offsite-c
```

From Mac/Windows client:

```bash
tailscale ping cloud-a
```

Also keep Nextcloud ports closed on the router (Tailscale-only access).

## Step 5 - Storage setup on Node A

Warning: this can wipe listed data disks if creating a new pool.

```bash
sudo ./cloud-foundation/phase-a/scripts/setup_node_a_storage.sh \
  --data-disks /dev/sdb,/dev/sdc \
  --pool ncdata \
  --dataset nextcloud \
  --mountpoint /srv/nextcloud/data \
  --wipe-confirmation I_UNDERSTAND
```

Pre-reboot validation:

```bash
sudo ./cloud-foundation/phase-a/scripts/validate_storage.sh \
  --pool ncdata \
  --dataset nextcloud \
  --mountpoint /srv/nextcloud/data \
  --expect-mirror \
  --mode prepare-reboot
```

Reboot Node A, then:

```bash
sudo ./cloud-foundation/phase-a/scripts/validate_storage.sh \
  --pool ncdata \
  --dataset nextcloud \
  --mountpoint /srv/nextcloud/data \
  --expect-mirror \
  --mode post-reboot
```

Validate:

- Mirror/filesystem reports healthy.
- Data path mounted after reboot.
- Marker file persists.

## Step 6 - Reliability setup (SMART + UPS)

On Node A:

```bash
sudo ./cloud-foundation/phase-a/scripts/setup_reliability.sh \
  --ups-name homeups \
  --ups-driver usbhid-ups \
  --ups-port auto \
  --ups-monitor-user upsmon \
  --ups-monitor-password "change-me-now"
```

Validate:

```bash
sudo ./cloud-foundation/phase-a/scripts/validate_reliability.sh --ups-name homeups
```

For simulated power-loss behavior (maintenance window only), run:

```bash
sudo ./cloud-foundation/phase-a/scripts/validate_reliability.sh \
  --ups-name homeups \
  --run-fsd-test
```

Keep one tested spare drive physically available for rapid replacement.

## Safety notes

- Run storage scripts only after confirming correct disk IDs (`lsblk`).
- Keep at least one active root/session open while hardening SSH.
- For UPS forced-shutdown tests, schedule downtime and have console access.
