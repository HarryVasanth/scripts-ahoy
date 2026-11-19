#!/usr/bin/env bash
set -euo pipefail

# Check which TCP ports answer on a host.
# Usage: port-check.sh <host> [ports] [timeout]
# Needs: nc (falls back to bash /dev/tcp)

usage() {
  printf 'Usage: %s <host> [ports] [timeout]\n  ports    Comma list or range. Default: 22,80,443,3306,5432,8080\n  timeout  Seconds to wait for each port. Default: 2\n' "${0##*/}"
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi
if [[ $# -lt 1 || -z ${1:-} ]]; then
  usage >&2
  exit 1
fi

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

host=$1
spec=${2:-22,80,443,3306,5432,8080}
timeout=${3:-2}
if ! [[ $timeout =~ ^[0-9]+$ ]] || ((timeout < 1)); then
  die 'the timeout must be a positive number of seconds.'
fi
[[ $host =~ ^[A-Za-z0-9._:-]+$ ]] || die "\"$host\" is not a valid host."

ports=()
IFS=',' read -r -a parts <<< "$spec"
for part in "${parts[@]}"; do
  if [[ $part == *-* ]]; then
    low=${part%-*} high=${part#*-}
    [[ $low =~ ^[0-9]+$ && $high =~ ^[0-9]+$ ]] || die "\"$part\" is not a port range."
    ((low >= 1 && high <= 65535 && low <= high)) || die "\"$part\" must sit in 1-65535."
    for ((n = low; n <= high; n++)); do ports+=("$n"); done
  else
    if ! [[ $part =~ ^[0-9]+$ ]] || ((part < 1 || part > 65535)); then
      die "\"$part\" is not a valid port."
    fi
    ports+=("$part")
  fi
done
((${#ports[@]} <= 1024)) || die "${#ports[@]} ports is too many. Use 1024 or fewer."

have_nc=0
if command -v nc > /dev/null 2>&1; then have_nc=1; fi
check_port() {
  if ((have_nc == 1)); then
    nc -z -w "$timeout" "$host" "$1" > /dev/null 2>&1
  else
    (exec 3<> "/dev/tcp/$host/$1") > /dev/null 2>&1
  fi
}

printf '🔌 %s (%d ports)\n' "$host" "${#ports[@]}"
open=0
for port in "${ports[@]}"; do
  if check_port "$port"; then
    printf '   ✅ %5s open\n' "$port"
    open=$((open + 1))
  else
    printf '   ⛔ %5s closed\n' "$port"
  fi
done
printf '📊 %d open, %d closed.\n' "$open" "$((${#ports[@]} - open))"
