#!/usr/bin/env bash
# Take, list or delete snapshots of one VM.
# Usage: vm-snapshot [-l] [-d NAME] [--dry-run] [-y] [-H user@host] VMID [NAME]
# Needs: qm (Proxmox VE)

set -euo pipefail
remote=
mode=create
snap=
dry_run=false
yes=false

usage() {
  cat << 'EOF'
Manage snapshots of one VM.
  -l, --list      List snapshots
  -d, --delete    Delete SNAPNAME
  --dry-run       Show the command and stop
  -y              Do not ask for confirmation
  -H USER@HOST    Run on a remote node over SSH
  -h, --help      Show this help

The default action takes a snapshot. The default name uses the date and time.
EOF
}

die() {
  printf '❌ %s\n' "$*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    -l | --list)
      mode=list
      shift
      ;;
    -d | --delete)
      mode=delete
      snap=${2:-}
      shift 2 || die "Option -d needs a name."
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -y)
      yes=true
      shift
      ;;
    -H)
      remote=${2:-}
      shift 2 || die "Option -H needs a value."
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

[ "$#" -ge 1 ] || {
  usage >&2
  die "Give me a VM ID."
}
vmid=$1
shift
case "$vmid" in '' | *[!0-9]*) die "The VM ID must be a number." ;; esac
[ "$#" -eq 0 ] || {
  [ -n "$snap" ] && die "Give the snapshot name only once."
  snap=$1
  shift
}
[ "$#" -eq 0 ] || die "Too many arguments."
if [ -n "$remote" ]; then
  command -v ssh > /dev/null 2>&1 || die "ssh is missing. Install OpenSSH."
  # shellcheck disable=SC2029  # The command must expand on the remote side.
  run() { ssh "$remote" "$@"; }
else
  command -v qm > /dev/null 2>&1 || die "qm is missing. This script must run on a Proxmox VE node."
  run() { "$@"; }
fi
run qm config "$vmid" > /dev/null 2>&1 || die "No VM with ID $vmid was found."

[ "$mode" != list ] || {
  run qm listsnapshot "$vmid"
  exit 0
}
snap=${snap:-snap-$(date +%Y%m%d-%H%M)}
case "$snap" in *[!A-Za-z0-9_-]*) die "The name may use letters, digits, dash and underscore only." ;; esac
cmd=(qm snapshot "$vmid" "$snap")
[ "$mode" = create ] || cmd=(qm delsnapshot "$vmid" "$snap")
printf '🗂️  VM %s, snapshot %s (%s)\n' "$vmid" "$snap" "$mode" >&2
[ "$dry_run" = false ] || {
  printf '🚧 Dry run. Would run: %s\n' "${cmd[*]}" >&2
  exit 0
}
if [ "$mode" = delete ] && [ "$yes" = false ]; then
  printf 'This deletes the snapshot. Continue? [y/N] '
  read -r reply
  case "$reply" in [yY] | [yY][eE][sS]) ;; *) die "Cancelled. Nothing was changed." ;; esac
fi
run "${cmd[@]}" || die "The command failed. Check the task log."
printf '✅ Done.\n' >&2
