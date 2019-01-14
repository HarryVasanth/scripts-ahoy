#!/usr/bin/env bash
# List backup files in a Proxmox storage.
# Usage: backup-list [-H user@host] [-s STORAGE] [--vmid VMID]
# Needs: pvesm (Proxmox VE)

set -euo pipefail
remote=
storage=local
vmid=

usage() {
  cat <<'EOF'
Show the backups that a storage holds.

Options:
  -H USER@HOST  Run on a remote node over SSH
  -s STORAGE    Storage name (default: local)
  --vmid VMID   Show one VM or container only
  -h, --help    Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -H) remote=${2:-}; shift 2 || die "Option -H needs a value." ;;
    -s) storage=${2:-}; shift 2 || die "Option -s needs a value." ;;
    --vmid) vmid=${2:-}; shift 2 || die "Option --vmid needs a value." ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

[ "$#" -eq 0 ] || die "Too many arguments."
[ -n "$storage" ] || die "The storage name cannot be empty."
[ -z "$vmid" ] || case "$vmid" in *[!0-9]*) die "The VM ID must be a number." ;; esac
if [ -n "$remote" ]; then
  command -v ssh >/dev/null 2>&1 || die "ssh is missing. Install OpenSSH."
  # shellcheck disable=SC2029  # The command must expand on the remote side.
  run() { ssh "$remote" "$@"; }
else
  command -v pvesm >/dev/null 2>&1 || die "pvesm is missing. This script must run on a Proxmox VE node."
  run() { "$@"; }
fi
args=(pvesm list "$storage" --content backup)
[ -z "$vmid" ] || args+=(--vmid "$vmid")
list=$(run "${args[@]}") || die "Cannot list storage '$storage'. Check the name and the node."
if [ -z "$list" ]; then
  printf '📭 No backups found in %s.\n' "$storage" >&2
  exit 0
fi
printf '🗄️  Backups in %s\n\n' "$storage" >&2
printf '%s\n' "$list"
