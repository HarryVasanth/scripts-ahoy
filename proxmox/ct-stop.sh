#!/usr/bin/env bash
# Stop a container, or stop it at once with --force.
# Usage: ct-stop [-H user@host] [-f] [--dry-run] [-y] CTID
# Needs: pct (Proxmox VE)

set -euo pipefail
remote=
force=false
dry_run=false
yes=false

usage() {
  cat << 'EOF'
Ask a container to shut down and wait for it. With --force, it stops at once,
which can lose data. The script asks before it changes anything.
  -H USER@HOST  Run on a remote node over SSH
  -f, --force   Stop the container without a graceful shutdown
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
  die "Give me exactly one container ID."
}
ctid=$1
case "$ctid" in '' | *[!0-9]*) die "The container ID must be a number." ;; esac
if [ -n "$remote" ]; then
  command -v ssh > /dev/null 2>&1 || die "ssh is missing. Install OpenSSH."
  # shellcheck disable=SC2029  # The command must expand on the remote side.
  run() { ssh "$remote" "$@"; }
else
  command -v pct > /dev/null 2>&1 || die "pct is missing. This script must run on a Proxmox VE node."
  run() { "$@"; }
fi
run pct config "$ctid" > /dev/null 2>&1 || die "No container with ID $ctid was found."
cmd=(pct shutdown "$ctid")
[ "$force" = false ] || cmd=(pct stop "$ctid")
printf '🛑 Container %s, action %s\n' "$ctid" "${cmd[1]}" >&2
if [ "$dry_run" = true ]; then
  printf '🚧 Dry run. Would run: %s\n' "${cmd[*]}" >&2
  exit 0
fi
if [ "$yes" = false ]; then
  printf 'This changes the container. Continue? [y/N] '
  read -r reply
  case "$reply" in [yY] | [yY][eE][sS]) ;; *) die "Cancelled. Nothing was changed." ;; esac
fi
run "${cmd[@]}" || die "The stop command failed. Check the task log."
printf '✅ Container %s: %s\n' "$ctid" "${cmd[1]}" >&2
