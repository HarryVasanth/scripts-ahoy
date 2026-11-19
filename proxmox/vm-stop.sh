#!/usr/bin/env bash
# Shut down a VM, or stop it at once with --force.
# Usage: vm-stop [-H user@host] [-f] [--dry-run] [-y] VMID
# Needs: qm (Proxmox VE)

set -euo pipefail
remote=
force=false
dry_run=false
yes=false

usage() {
  cat << 'EOF'
Ask a VM to shut down and wait for it. With --force, the VM stops at once,
which can lose data. The script asks before it changes anything.
  -H USER@HOST  Run on a remote node over SSH
  -f, --force   Stop the VM without a graceful shutdown
  --dry-run     Show the command and stop
  -y            Do not ask for confirmation
  -h, --help    Show this help
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
    -f | --force)
      force=true
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

[ "$#" -eq 1 ] || {
  usage >&2
  die "Give me exactly one VM ID."
}
vmid=$1
case "$vmid" in '' | *[!0-9]*) die "The VM ID must be a number." ;; esac
if [ -n "$remote" ]; then
  command -v ssh > /dev/null 2>&1 || die "ssh is missing. Install OpenSSH."
  # shellcheck disable=SC2029  # The command must expand on the remote side.
  run() { ssh "$remote" "$@"; }
else
  command -v qm > /dev/null 2>&1 || die "qm is missing. This script must run on a Proxmox VE node."
  run() { "$@"; }
fi
run qm config "$vmid" > /dev/null 2>&1 || die "No VM with ID $vmid was found."
cmd=(qm shutdown "$vmid")
[ "$force" = false ] || cmd=(qm stop "$vmid")
printf '🛑 VM %s, action %s\n' "$vmid" "${cmd[1]}" >&2
if [ "$dry_run" = true ]; then
  printf '🚧 Dry run. Would run: %s\n' "${cmd[*]}" >&2
  exit 0
fi
if [ "$yes" = false ]; then
  printf 'This changes the VM. Continue? [y/N] '
  read -r reply
  case "$reply" in [yY] | [yY][eE][sS]) ;; *) die "Cancelled. Nothing was changed." ;; esac
fi
run "${cmd[@]}" || die "The stop command failed. Check the task log."
printf '✅ VM %s: %s\n' "$vmid" "${cmd[1]}" >&2
