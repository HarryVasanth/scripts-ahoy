#!/usr/bin/env bash
# Take, list, roll back or delete snapshots of one container.
# Usage: pct-snapshot [-l] [-r NAME] [-d NAME] [--dry-run] [-y] CTID [SNAPNAME]
# Needs: pct (Proxmox VE)
# Note: Rollback and delete change the container. The script asks first.

set -euo pipefail
mode=create
snap=
dry_run=false
yes=false

usage() {
  cat <<'EOF'
Manage snapshots of one LXC container.
  -l, --list      List snapshots
  -r, --rollback  Roll back to SNAPNAME
  -d, --destroy   Delete SNAPNAME
  --dry-run       Show the command and stop
  -y              Do not ask for confirmation
  -h, --help      Show this help

The default action takes a snapshot. The default name uses the date and time.
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -l|--list) mode=list; shift ;;
    -r|--rollback) mode=rollback; snap=${2:-}; shift 2 || die "Option -r needs a name." ;;
    -d|--destroy) mode=destroy; snap=${2:-}; shift 2 || die "Option -d needs a name." ;;
    --dry-run) dry_run=true; shift ;;
    -y) yes=true; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

[ "$#" -ge 1 ] || { usage >&2; die "Give me a container ID."; }
ctid=$1; shift
case "$ctid" in
  ''|*[!0-9]*) die "The container ID must be a number." ;;
esac
if [ "$#" -gt 0 ]; then
  [ -n "$snap" ] && die "Give the snapshot name only once."
  snap=$1
  shift
fi
[ "$#" -eq 0 ] || die "Too many arguments."
[ "$(id -u)" -eq 0 ] || die "Run this script as root."
command -v pct >/dev/null 2>&1 || die "pct is missing. This script must run on a Proxmox VE node."
pct status "$ctid" >/dev/null 2>&1 || die "No container with ID $ctid was found."

if [ "$mode" = list ]; then pct listsnapshot "$ctid"; exit 0; fi
snap=${snap:-snap-$(date +%Y%m%d-%H%M)}
case "$snap" in
  *[!A-Za-z0-9_-]*) die "The snapshot name may use letters, digits, dash and underscore only." ;;
esac
case "$mode" in
  create) cmd=(pct snapshot "$ctid" "$snap") ;;
  rollback) cmd=(pct rollback "$ctid" "$snap") ;;
  destroy) cmd=(pct delsnapshot "$ctid" "$snap" --force) ;;
esac

printf '🗂️  Container %s, snapshot %s (%s)\n' "$ctid" "$snap" "$mode" >&2
if [ "$dry_run" = true ]; then
  printf '🚧 Dry run. Would run: %s\n' "${cmd[*]}" >&2
  exit 0
fi
if [ "$mode" != create ] && [ "$yes" = false ]; then
  printf 'This changes the container. Continue? [y/N] '
  read -r reply
  case "$reply" in [yY]|[yY][eE][sS]) ;; *) die "Cancelled. Nothing was changed." ;; esac
fi
"${cmd[@]}"
printf '✅ Done.\n' >&2
