#!/usr/bin/env bash
set -euo pipefail

# Test whether a name server allows a zone transfer.
# Usage: axfr-check.sh <domain>
# Needs: dig
# Note: Test only a domain that you own or may test.

usage() {
  printf 'Usage: %s <domain>\nExample: %s example.com\n' "${0##*/}" "${0##*/}"
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

domain=$1
[[ $domain =~ ^[A-Za-z0-9._-]+$ ]] \
  || {
    printf 'Error: "%s" is not a valid domain.\n' "$domain" >&2
    exit 1
  }

servers=$(dig +short NS "$domain" 2> /dev/null | sed 's/\.$//') || servers=""
if [[ -z $servers ]]; then
  printf '❌ No NS records for %s.\n' "$domain" >&2
  exit 1
fi

printf '🗂️  Zone transfer test for %s\n' "$domain"
open=0
for ns in $servers; do
  answer=$(dig +time=5 +tries=1 AXFR "@$ns" "$domain" 2> /dev/null) || answer=""
  if printf '%s' "$answer" | grep -q 'SOA'; then
    printf '   ⚠️  %s allows a transfer.\n' "$ns"
    printf '%s\n' "$answer" | head -n 4 | sed 's/^/      /'
    open=1
  else
    printf '   ✅ %s refuses the transfer.\n' "$ns"
  fi
done

if ((open == 1)); then
  printf '❗ Restrict AXFR to your secondary servers.\n'
  exit 1
fi
printf '✅ No name server allowed a transfer.\n'
