#!/usr/bin/env bash
# Show a short configuration summary for one VM.
# Usage: vm-config [-H user@host] VMID
# Needs: qm (Proxmox VE)

set -euo pipefail
remote=

usage() {
  cat <<'EOF'
Print the name, hardware, disks and network of one VM.

Options:
  -H USER@HOST  Run on a remote node over SSH
  -h, --help    Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -H) remote=${2:-}; shift 2 || die "Option -H needs a value." ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

[ "$#" -eq 1 ] || { usage >&2; die "Give me exactly one VM ID."; }
vmid=$1
case "$vmid" in ''|*[!0-9]*) die "The VM ID must be a number." ;; esac
if [ -n "$remote" ]; then
  command -v ssh >/dev/null 2>&1 || die "ssh is missing. Install OpenSSH."
  # shellcheck disable=SC2029  # The command must expand on the remote side.
  run() { ssh "$remote" "$@"; }
else
  command -v qm >/dev/null 2>&1 || die "qm is missing. This script must run on a Proxmox VE node."
  run() { "$@"; }
fi
cfg=$(run qm config "$vmid") || die "No VM with ID $vmid was found."
status=$(run qm status "$vmid" | awk '{print $2}') || die "Cannot read the status of VM $vmid."
printf 'VM %s, status %s\n\n' "$vmid" "$status"
printf '%s\n' "$cfg" | grep -E '^(name|ostype|cores|sockets|cpu|memory|balloon|onboot|boot|bootdisk|agent|net[0-9]+|(scsi|virtio|sata|ide)[0-9]+):' || true
