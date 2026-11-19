#!/usr/bin/env bash
# Start a VM and wait until it reports running.
# Usage: vm-start [-H user@host] [-t SECONDS] VMID
# Needs: qm (Proxmox VE)

set -euo pipefail
remote=
timeout=60

usage() {
  cat << 'EOF'
Start one VM and wait for the running state.

Options:
  -H USER@HOST  Run on a remote node over SSH
  -t SECONDS    How long to wait (default: 60)
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
    -t)
      timeout=${2:-}
      shift 2 || die "Option -t needs a value."
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
case "$timeout" in '' | *[!0-9]*) die "The timeout must be a whole number." ;; esac
if [ -n "$remote" ]; then
  command -v ssh > /dev/null 2>&1 || die "ssh is missing. Install OpenSSH."
  # shellcheck disable=SC2029  # The command must expand on the remote side.
  run() { ssh "$remote" "$@"; }
else
  command -v qm > /dev/null 2>&1 || die "qm is missing. This script must run on a Proxmox VE node."
  run() { "$@"; }
fi

run qm config "$vmid" > /dev/null 2>&1 || die "No VM with ID $vmid was found."
status=$(run qm status "$vmid" | awk '{print $2}') || die "Cannot read the status of VM $vmid."
if [ "$status" = running ]; then
  printf '✅ VM %s is already running.\n' "$vmid" >&2
  exit 0
fi
printf '▶️  Starting VM %s...\n' "$vmid" >&2
run qm start "$vmid" || die "The start command failed. Check the task log."
i=0
while [ "$i" -lt "$timeout" ]; do
  sleep 1
  status=$(run qm status "$vmid" | awk '{print $2}') || die "Cannot read the status of VM $vmid."
  if [ "$status" = running ]; then
    printf '✅ VM %s is running.\n' "$vmid" >&2
    exit 0
  fi
  i=$((i + 1))
done
die "VM $vmid did not start within $timeout seconds. Check the task log."
