#!/usr/bin/env bash
# Back up one VM or container with vzdump.
# Usage: vm-backup [-s STORAGE] [-m MODE] [-c COMPRESS] [--dry-run] [-y] VMID
# Needs: vzdump, qm or pct (Proxmox VE)
# Note: Check the free space on the target storage before a large backup.

set -euo pipefail
storage=local
mode=snapshot
compress=zstd
dry_run=false
yes=false

usage() {
  cat <<'EOF'
Back up one VM or container to a Proxmox storage.
  -s STORAGE   Target storage (default: local)
  -m MODE      snapshot, suspend or stop (default: snapshot)
  -c COMPRESS  zstd, gzip, lzo or 0 (default: zstd)
  --dry-run    Show the command and stop
  -y           Do not ask for confirmation
  -h, --help   Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -s) storage=${2:-}; shift 2 || die "Option -s needs a value." ;;
    -m) mode=${2:-}; shift 2 || die "Option -m needs a value." ;;
    -c) compress=${2:-}; shift 2 || die "Option -c needs a value." ;;
    --dry-run) dry_run=true; shift ;;
    -y) yes=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done
[ "$#" -eq 1 ] || { usage >&2; die "Give me exactly one VM or container ID."; }
vmid=$1
case "$vmid" in
  ''|*[!0-9]*) die "The VM ID must be a number." ;;
esac
case "$mode" in
  snapshot|suspend|stop) ;;
  *) die "Mode must be snapshot, suspend or stop." ;;
esac
case "$compress" in
  zstd|gzip|lzo|0) ;;
  *) die "Compression must be zstd, gzip, lzo or 0." ;;
esac
[ "$(id -u)" -eq 0 ] || die "Run this script as root."
command -v vzdump >/dev/null 2>&1 || die "vzdump is missing. This script must run on a Proxmox VE node."

if command -v qm >/dev/null 2>&1 && qm config "$vmid" >/dev/null 2>&1; then
  kind=VM
elif command -v pct >/dev/null 2>&1 && pct config "$vmid" >/dev/null 2>&1; then
  kind=CT
else
  die "No VM or container with ID $vmid was found."
fi
if command -v pvesm >/dev/null 2>&1; then
  pvesm status | awk '{print $1}' | grep -qx "$storage" || die "Storage '$storage' is not active."
fi

cmd=(vzdump "$vmid" --mode "$mode" --compress "$compress" --storage "$storage")
printf '📦 Backing up %s %s to %s (%s, %s)\n' "$kind" "$vmid" "$storage" "$mode" "$compress" >&2
if [ "$dry_run" = true ]; then
  printf '🚧 Dry run. Would run: %s\n' "${cmd[*]}" >&2
  exit 0
fi
if [ "$yes" = false ]; then
  printf 'Continue? [y/N] '
  read -r reply
  case "$reply" in [yY]|[yY][eE][sS]) ;; *) die "Cancelled. Nothing was changed." ;; esac
fi
"${cmd[@]}"
printf '✅ Backup of %s finished.\n' "$vmid" >&2
