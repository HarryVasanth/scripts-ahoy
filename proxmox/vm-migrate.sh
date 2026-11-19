#!/usr/bin/env bash
# Migrate a VM to another cluster node.
# Usage: vm-migrate [-H user@host] [--online] [--with-local-disks] [--dry-run] [-y] VMID NODE
# Needs: qm (Proxmox VE)
# Note: A migration changes the VM. The script asks first.

set -euo pipefail
remote=
online=false
local_disks=false
dry_run=false
yes=false

usage() {
  cat << 'EOF'
Move one VM to another node. Live migration needs shared storage.
  -H USER@HOST        Run on a remote node over SSH
  --online            Migrate while the VM runs
  --with-local-disks  Copy local disks to the target node
  --dry-run           Show the command and stop
  -y                  Do not ask for confirmation
  -h, --help          Show this help
EOF
}

die() {
  printf '❌ %s\n' "$*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    -H)
      remote=${2:-}
      shift 2 || die "Option -H needs a value."
      ;;
    --online)
      online=true
      shift
      ;;
    --with-local-disks)
      local_disks=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -y)
      yes=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

[ "$#" -eq 2 ] || {
  usage >&2
  die "Give me a VM ID and a target node."
}
vmid=$1
node=$2
case "$vmid" in '' | *[!0-9]*) die "The VM ID must be a number." ;; esac
case "$node" in *[!A-Za-z0-9._-]*) die "The node name has an unexpected character." ;; esac
if [ -n "$remote" ]; then
  command -v ssh > /dev/null 2>&1 || die "ssh is missing. Install OpenSSH."
  # shellcheck disable=SC2029  # The command must expand on the remote side.
  run() { ssh "$remote" "$@"; }
else
  command -v qm > /dev/null 2>&1 || die "qm is missing. This script must run on a Proxmox VE node."
  run() { "$@"; }
fi
run qm config "$vmid" > /dev/null 2>&1 || die "No VM with ID $vmid was found."
cmd=(qm migrate "$vmid" "$node")
[ "$online" = false ] || cmd+=(--online)
[ "$local_disks" = false ] || cmd+=(--with-local-disks)
printf '🚚 VM %s -> %s\n' "$vmid" "$node" >&2
if [ "$dry_run" = true ]; then
  printf '🚧 Dry run. Would run: %s\n' "${cmd[*]}" >&2
  exit 0
fi
if [ "$yes" = false ]; then
  printf 'This moves the VM. Continue? [y/N] '
  read -r reply
  case "$reply" in [yY] | [yY][eE][sS]) ;; *) die "Cancelled. Nothing was changed." ;; esac
fi
run "${cmd[@]}" || die "The migration failed. Check the task log."
printf '✅ VM %s moved to %s.\n' "$vmid" "$node" >&2
