#!/usr/bin/env bash
# Report the health of a Proxmox cluster: quorum, nodes and services.
# Usage: cluster-health [-H user@host]
# Needs: pvecm, pvesh, jq (Proxmox VE)

set -euo pipefail

remote=

usage() {
  cat <<'EOF'
Check quorum, node state and failed services.
Use -H to run the checks on another node over SSH.

Options:
  -H USER@HOST  Run on a remote node
  -h, --help    Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    -H) remote=${2:-}; shift 2 || die "Option -H needs a value." ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

if [ -n "$remote" ]; then
  # shellcheck disable=SC2029  # The command must expand on the remote side.
  run() { ssh "$remote" "$@"; }
else
  run() { "$@"; }
fi

for tool in pvecm pvesh jq; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool is missing. This script must run on a Proxmox VE node."
done

printf '🩺 Cluster health\n\n'
printf 'Quorum:\n'
if quorum=$(run pvecm status 2>/dev/null); then
  printf '%s\n' "$quorum" | grep -E '^(Cluster name|Quorum|Nodes|Expected votes|Highest expected|Flags)' || true
else
  printf '   This node is not in a cluster.\n'
fi

printf '\nNodes:\n'
run pvesh get /cluster/resources --type node --output-format json \
  | jq -r '.[] | [.node, (.status // "?"), (((.cpu // 0) * 100) | floor), (if (.maxmem // 0) > 0 then (((.mem // 0) * 100 / .maxmem) | floor) else 0 end), (((.uptime // 0) / 86400) | floor)] | @tsv' \
  | awk -F'\t' 'BEGIN { printf "   %-20s %-8s %5s %5s %7s\n", "NODE", "STATUS", "CPU%", "MEM%", "UP_DAYS" }
                { printf "   %-20s %-8s %5s %5s %7s\n", $1, $2, $3, $4, $5 }'

printf '\nServices that are not running:\n'
nodes=$(run pvesh get /nodes --output-format json | jq -r '.[].node')
failed=$(for node in $nodes; do
  run pvesh get "/nodes/$node/services" --output-format json \
    | jq -r --arg n "$node" '.[] | select(.state != "running") | "   \($n): \(.name) (\(.state))"'
done)
if [ -n "$failed" ]; then
  printf '%s\n' "$failed"
else
  printf '   All services are running.\n'
fi
