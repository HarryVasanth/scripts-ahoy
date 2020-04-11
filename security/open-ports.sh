#!/usr/bin/env bash
# List listening TCP and bound UDP ports.
# Usage: open-ports.sh [-h]
# Note: Process names for other users need sudo.

set -euo pipefail

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    *) die "unknown option $1" ;;
  esac
done

if command -v ss >/dev/null 2>&1; then
  printf '🔎 Listening TCP and UDP sockets\n\n'
  ss -tulpn 2>/dev/null || ss -tuln
elif command -v lsof >/dev/null 2>&1; then
  printf '🔎 TCP listeners\n\n'
  lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null |
    awk 'NR > 1 { printf "%-18s %-7s %-10s %s\n", $1, $2, $3, $9 }' || true
  printf '\n🔎 UDP sockets\n\n'
  lsof -nP -iUDP 2>/dev/null |
    awk 'NR > 1 { printf "%-18s %-7s %-10s %s\n", $1, $2, $3, $9 }' || true
else
  printf '🔎 Listening sockets\n\n'
  netstat -an 2>/dev/null | grep -E 'LISTEN|UDP' || true
fi
