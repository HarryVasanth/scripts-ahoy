#!/usr/bin/env bash
# Show free space for Proxmox storages and, when present, ZFS pools.
# Usage: storage-usage [-H user@host] [--node NODE]
# Needs: pvesh, jq (Proxmox VE); zpool is used when present.

set -euo pipefail

remote=
node=

usage() {
  cat << 'EOF'
Print used and total space for each storage in gigabytes.
ZFS pools are shown when the zpool command is available.

Options:
  -H USER@HOST  Run on a remote node
  --node NODE   Show one node only
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
    --node)
      node=${2:-}
      shift 2 || die "Option --node needs a value."
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "Unknown option: $1" ;;
  esac
done

if [ -n "$remote" ]; then
  # shellcheck disable=SC2029  # The command must expand on the remote side.
  run() { ssh "$remote" "$@"; }
else
  run() { "$@"; }
fi

for tool in pvesh jq; do
  command -v "$tool" > /dev/null 2>&1 || die "$tool is missing. This script must run on a Proxmox VE node."
done

printf '💾 Storages:\n'
printf '   %-18s %-12s %-8s %6s %6s %5s\n' NAME NODE STATUS USED/GB TOTAL/GB USE%
run pvesh get /cluster/resources --type storage --output-format json \
  | jq -r --arg node "$node" '
      .[] | select(.type == "storage")
      | select($node == "" or .node == $node)
      | [.storage, .node, (.status // "?"),
         (((.disk // 0) / 1073741824) | floor),
         (((.maxdisk // 0) / 1073741824) | floor),
         (if (.maxdisk // 0) > 0 then (((.disk // 0) * 100 / .maxdisk) | floor) else 0 end)]
      | @tsv' \
  | awk -F'\t' '{ printf "   %-18s %-12s %-8s %6s %6s %4s%%\n", $1, $2, $3, $4, $5, $6 }'

if [ -n "$remote" ] || command -v zpool > /dev/null 2>&1; then
  pools=$(run zpool list -H -o name,size,alloc,free,cap,health 2> /dev/null) || pools=
  if [ -n "$pools" ]; then
    printf '\n💽 ZFS pools:\n'
    printf '   %-18s %6s %6s %6s %5s %s\n' NAME SIZE ALLOC FREE USE HEALTH
    printf '%s\n' "$pools" | awk -F'\t' '{ printf "   %-18s %6s %6s %6s %5s %s\n", $1, $2, $3, $4, $5, $6 }'
  fi
fi
