#!/usr/bin/env bash
set -euo pipefail

# Show packet loss and the min, avg, and max latency to a host.
# Usage: ping-stats.sh [count] <host>
# Needs: ping, awk

usage() {
  printf 'Usage: %s [count] <host>\n  count  Number of packets. Default: 5\n' "${0##*/}"
}
args=()
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    -*) printf 'Error: unknown option "%s".\n' "$arg" >&2; exit 1 ;;
    *) args+=("$arg") ;;
  esac
done
if (( ${#args[@]} < 1 )); then usage >&2; exit 1; fi

if (( ${#args[@]} == 1 )); then
  count=5
  host=${args[0]}
else
  count=${args[0]}
  host=${args[1]}
fi
[[ $count =~ ^[1-9][0-9]*$ ]] \
  || { printf 'Error: count must be from 1 to 100.\n' >&2; exit 1; }
(( count <= 100 )) \
  || { printf 'Error: count must be from 1 to 100.\n' >&2; exit 1; }
[[ $host =~ ^[A-Za-z0-9._:-]+$ ]] \
  || { printf 'Error: "%s" is not a valid host.\n' "$host" >&2; exit 1; }
command -v ping >/dev/null 2>&1 || { printf 'Error: ping is not installed.\n' >&2; exit 1; }

out=$(ping -c "$count" "$host" 2>&1) || true
loss=$(printf '%s\n' "$out" | sed -n 's/.* \([0-9.]*\)% packet loss.*/\1/p' | head -n 1)
stats=$(printf '%s\n' "$out" | awk -F'= ' '/min\/avg\/max/ { print $2; exit }')
stats=${stats% ms}

printf '📡 %s (%s packets)\n' "$host" "$count"
if [[ -n $loss ]]; then
  printf '   Packet loss: %s%%\n' "$loss"
fi
if [[ -z $stats ]]; then
  printf '   ❌ No replies. The host may be down or block ping.\n' >&2
  exit 1
fi
IFS='/' read -r min avg max _ <<< "$stats"
printf '   Latency:     min %s ms, avg %s ms, max %s ms\n' "$min" "$avg" "$max"
