#!/usr/bin/env bash
# List VMs and containers across a Proxmox cluster with live usage.
# Usage: vm-list [-H user@host] [--type vm|ct|all] [--node NODE]
# Needs: pvesh, jq (Proxmox VE)

set -euo pipefail

remote=
type=all
node=

usage() {
  cat <<'EOF'
Show every VM and container in the cluster.

Options:
  -H USER@HOST  Run on a remote node
  --type TYPE   vm, ct or all (default: all)
  --node NODE   Show one node only
  -h, --help    Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -H) remote=${2:-}; shift 2 || die "Option -H needs a value." ;;
    --type) type=${2:-}; shift 2 || die "Option --type needs a value." ;;
    --node) node=${2:-}; shift 2 || die "Option --node needs a value." ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

case "$type" in
  vm|ct|all) ;;
  *) die "Type must be vm, ct or all." ;;
esac

if [ -n "$remote" ]; then
  get() { ssh "$remote" pvesh get /cluster/resources --output-format json; }
else
  get() { pvesh get /cluster/resources --output-format json; }
fi

for tool in pvesh jq; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool is missing. This script must run on a Proxmox VE node."
done

printf '%-6s %-24s %-5s %-8s %-12s %5s %10s %9s\n' VMID NAME TYPE STATUS NODE CPU% MEM/MB UP_HOURS
get | jq -r --arg type "$type" --arg node "$node" '
  sort_by(.vmid) | .[]
  | select(.type == "qemu" or .type == "lxc")
  | select($type == "all" or (.type == "qemu" and $type == "vm") or (.type == "lxc" and $type == "ct"))
  | select($node == "" or .node == $node)
  | [.vmid, (.name // "-"), (if .type == "qemu" then "VM" else "CT" end),
     (.status // "?"), (.node // "-"), (((.cpu // 0) * 100) | floor),
     (((.mem // 0) / 1048576) | floor), (((.maxmem // 0) / 1048576) | floor),
     (((.uptime // 0) / 3600) | floor)] | @tsv' \
  | awk -F'\t' '{ printf "%-6s %-24s %-5s %-8s %-12s %5s %5s/%-4s %9s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9 }'
