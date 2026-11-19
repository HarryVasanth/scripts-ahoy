#!/usr/bin/env bash
set -euo pipefail

# Show the common DNS records for a name.
# Usage: dns-records.sh <name>
# Needs: dig

usage() {
  printf 'Usage: %s <name>\n  Shows A, AAAA, MX, NS, TXT, SOA, and CAA records.\n' "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi
if [[ $# -lt 1 || -z ${1:-} ]]; then
  usage >&2
  exit 1
fi
command -v dig > /dev/null 2>&1 \
  || {
    printf 'Error: dig is not installed. Try: brew install bind or apt install dnsutils.\n' >&2
    exit 1
  }

name=$1
[[ $name =~ ^[A-Za-z0-9._-]+$ ]] \
  || {
    printf 'Error: "%s" is not a valid name.\n' "$name" >&2
    exit 1
  }

printf '🗂️  DNS records for %s\n' "$name"
for type in A AAAA MX NS TXT SOA CAA; do
  answer=$(dig +short +time=3 +tries=1 "$name" "$type" 2> /dev/null | tr -d '"') || answer=""
  if [[ -z $answer ]]; then
    printf '   %-5s (none)\n' "$type"
  else
    printf '   %-5s %s\n' "$type" "$(printf '%s' "$answer" | head -n 1)"
    if (($(printf '%s\n' "$answer" | wc -l | tr -d ' ') > 1)); then
      printf '%s\n' "$answer" | tail -n +2 | sed 's/^/         /'
    fi
  fi
done
