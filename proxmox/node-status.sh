#!/usr/bin/env bash
# Show CPU, RAM and storage status for one node.
# Usage: node-status [-H user@host] [--node NODE]
# Needs: pvesh, jq (Proxmox VE)

set -euo pipefail
remote=
node=

usage() {
  cat << 'EOF'
Print live usage for one node and its storages.

Options:
  -H USER@HOST  Run on a remote node over SSH
  --node NODE   Node to inspect (default: the node name on the host)
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
    --)
      shift
      break
      ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

[ "$#" -eq 0 ] || die "Too many arguments."
if [ -n "$remote" ]; then
  command -v ssh > /dev/null 2>&1 || die "ssh is missing. Install OpenSSH."
  # shellcheck disable=SC2029  # The command must expand on the remote side.
  run() { ssh "$remote" "$@"; }
else
  command -v pvesh > /dev/null 2>&1 || die "pvesh is missing. This script must run on a Proxmox VE node."
  run() { "$@"; }
fi
command -v jq > /dev/null 2>&1 || die "jq is missing. Install it with: sudo apt install jq."
[ -n "$node" ] || node=$(run hostname -s) || die "Cannot read the node name. Use --node."
status=$(run pvesh get "/nodes/$node/status" --output-format json) || die "Cannot read node '$node'."
printf '🖥️  Node %s\n\n' "$node"
printf '%s\n' "$status" | jq -r '
  "CPU:   \(.cpu * 100 | floor)%",
  "Load:  \(.loadavg[0]), \(.loadavg[1]), \(.loadavg[2])",
  "RAM:   \((.memory.used // 0) / 1073741824 | floor) GiB of \((.memory.total // 0) / 1073741824 | floor) GiB",
  "Root:  \((.rootfs.used // 0) / 1073741824 | floor) GiB of \((.rootfs.total // 0) / 1073741824 | floor) GiB"'
printf '\nStorage:\n'
run pvesh get "/nodes/$node/storage" --output-format json | jq -r '.[] |
  [.storage, (.type // "-"), (.active // false),
   (((.used // 0) / 1073741824 * 10 | round) / 10),
   (((.total // 0) / 1073741824 * 10 | round) / 10)] | @tsv' \
  | awk -F'\t' 'BEGIN { printf "%-16s %-8s %-6s %8s %8s\n", "NAME", "TYPE", "ACTIVE", "USED/G", "TOTAL/G" }
    { printf "%-16s %-8s %-6s %8.1f %8.1f\n", $1, $2, $3, $4, $5 }'
