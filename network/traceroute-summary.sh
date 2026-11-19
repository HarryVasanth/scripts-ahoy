#!/usr/bin/env bash
set -euo pipefail

# Summarise the route to a host: hop count, loss and last reply.
# Usage: traceroute-summary.sh <host> [max-hops]
# Needs: traceroute

usage() {
  printf 'Usage: %s <host> [max-hops]\n' "${0##*/}"
  printf '  max-hops  Highest hop to probe. Default: 20\n'
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi
if [[ $# -lt 1 || -z ${1:-} ]]; then
  usage >&2
  exit 1
fi

if ! command -v traceroute > /dev/null 2>&1; then
  printf 'Error: traceroute is not installed.\n' >&2
  printf 'Install it: brew install traceroute (macOS) or apt install traceroute (Debian).\n' >&2
  exit 1
fi

host=$1
max_hops=${2:-20}
if [[ ! $host =~ ^[A-Za-z0-9._:-]+$ ]]; then
  printf 'Error: "%s" is not a valid host.\n' "$host" >&2
  exit 1
fi
if [[ ! $max_hops =~ ^[0-9]+$ ]] || ((max_hops < 1 || max_hops > 64)); then
  printf 'Error: max-hops must be a number from 1 to 64.\n' >&2
  exit 1
fi

trace=$(traceroute -n -q 1 -w 1 -m "$max_hops" "$host" 2>&1 || true)
if [[ -z $trace ]]; then
  printf 'Error: traceroute gave no answer for "%s".\n' "$host" >&2
  exit 1
fi
case "$trace" in
  *"Unknown host"* | *"unknown host"* | *"Name or service not known"*)
    printf 'Error: cannot resolve "%s".\n' "$host" >&2
    exit 1
    ;;
esac

printf '🧭 Route to %s\n' "$host"
printf '%s\n' "$trace" | awk 'NR > 1 {
  hops++
  if ($2 == "*") { lost++ } else { seen++; last = $2; rtt = $3 }
}
END {
  if (hops == 0) { print "   No hops found."; exit 1 }
  printf "   Hops probed: %d\n", hops
  printf "   Replies: %d, timeouts: %d\n", seen, lost
  if (seen > 0) { printf "   Last reply: %s at %s ms\n", last, rtt }
}'

printf '   Path:\n'
printf '%s\n' "$trace" | awk 'NR > 1 && $2 != "*" { printf "   %s  %s\n", $1, $2 }'
