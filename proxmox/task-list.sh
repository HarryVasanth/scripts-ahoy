#!/usr/bin/env bash
# Show recent tasks from the cluster task log.
# Usage: task-list [-H user@host] [-n LIMIT]
# Needs: pvesh, jq (Proxmox VE)

set -euo pipefail
remote=
limit=20

usage() {
  cat << 'EOF'
Print the most recent tasks, newest first.

Options:
  -H USER@HOST  Run on a remote node over SSH
  -n LIMIT      Number of tasks to show (default: 20)
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
    -n)
      limit=${2:-}
      shift 2 || die "Option -n needs a value."
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
case "$limit" in '' | *[!0-9]*) die "The limit must be a whole number." ;; esac
[ "$limit" -ge 1 ] || die "The limit must be 1 or more."
if [ -n "$remote" ]; then
  command -v ssh > /dev/null 2>&1 || die "ssh is missing. Install OpenSSH."
  # shellcheck disable=SC2029  # The command must expand on the remote side.
  run() { ssh "$remote" "$@"; }
else
  command -v pvesh > /dev/null 2>&1 || die "pvesh is missing. This script must run on a Proxmox VE node."
  run() { "$@"; }
fi
command -v jq > /dev/null 2>&1 || die "jq is missing. Install it with: sudo apt install jq."
tasks=$(run pvesh get /cluster/tasks --output-format json) || die "Cannot read the task log."
if date -r 0 '+%s' > /dev/null 2>&1; then
  fmt_date() { date -r "$1" '+%Y-%m-%d %H:%M'; }
else
  fmt_date() { date -d "@$1" '+%Y-%m-%d %H:%M'; }
fi
printf '%-16s %-12s %-14s %-8s %s\n' "START" "NODE" "TYPE" "STATUS" "ID"
printf '%s\n' "$tasks" | jq -r --argjson n "$limit" '
  sort_by(.starttime) | reverse | .[:$n] | .[]
  | [(.starttime | tostring), .node, .type, (.status // "running"), (.id // "-")] | @tsv' \
  | while IFS=$'\t' read -r start node type status id; do
    printf '%-16s %-12s %-14s %-8s %s\n' "$(fmt_date "$start")" "$node" "$type" "$status" "$id"
  done || die "Cannot format the task list."
