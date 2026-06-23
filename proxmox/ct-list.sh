#!/usr/bin/env bash
# List containers across the cluster with status.
# Usage: ct-list [-H user@host] [--node NODE]
# Needs: pvesh, jq (Proxmox VE)

set -euo pipefail
remote=
node=

usage() {
  cat <<'EOF'
Show every container and its live state.

Options:
  -H USER@HOST  Run on a remote node over SSH
  --node NODE   Show one node only
  -h, --help    Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -H) remote=${2:-}; shift 2 || die "Option -H needs a value." ;;
    --node) node=${2:-}; shift 2 || die "Option --node needs a value." ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

if [ -n "$remote" ]; then
  command -v ssh >/dev/null 2>&1 || die "ssh is missing. Install OpenSSH."
  # shellcheck disable=SC2029  # The command must expand on the remote side.
  get() { ssh "$remote" pvesh get /cluster/resources --output-format json; }
else
  command -v pvesh >/dev/null 2>&1 || die "pvesh is missing. This script must run on a Proxmox VE node."
  get() { pvesh get /cluster/resources --output-format json; }
fi
command -v jq >/dev/null 2>&1 || die "jq is missing. Install it with: sudo apt install jq."

printf '%-6s %-24s %-8s %-12s %5s %10s %9s\n' VMID NAME STATUS NODE CPU% MEM/MB UP_HOURS
get | jq -r --arg node "$node" '
  sort_by(.vmid) | .[]
  | select(.type == "lxc")
  | select($node == "" or .node == $node)
  | [.vmid, (.name // "-"), (.status // "?"), (.node // "-"),
     (((.cpu // 0) * 100) | floor),
     (((.mem // 0) / 1048576) | floor), (((.maxmem // 0) / 1048576) | floor),
     (((.uptime // 0) / 3600) | floor)] | @tsv' \
  | awk -F'\t' '{ printf "%-6s %-24s %-8s %-12s %5s %5s/%-4s %9s\n", $1, $2, $3, $4, $5, $6, $7, $8 }'
