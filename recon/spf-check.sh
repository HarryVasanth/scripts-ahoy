#!/usr/bin/env bash
set -euo pipefail

# Fetch and explain a domain's SPF record.
# Usage: spf-check.sh <domain>
# Needs: dig

usage() {
  printf 'Usage: %s <domain>\nExample: %s example.com\n' "${0##*/}" "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then usage; exit 0; fi
if [[ $# -lt 1 || -z ${1:-} ]]; then usage >&2; exit 1; fi
command -v dig >/dev/null 2>&1 \
  || { printf 'Error: dig is not installed. Try: brew install bind or apt install dnsutils.\n' >&2; exit 1; }

domain=$1
[[ $domain =~ ^[A-Za-z0-9._-]+$ ]] \
  || { printf 'Error: "%s" is not a valid domain.\n' "$domain" >&2; exit 1; }

spfs=$(dig +short TXT "$domain" 2>/dev/null | tr -d '"' | grep -i '^v=spf1') || spfs=""
count=$(printf '%s\n' "$spfs" | awk 'NF { n++ } END { print n + 0 }')
if (( count == 0 )); then
  printf '❌ %s has no SPF record.\n' "$domain"
  exit 1
fi
record=$(printf '%s\n' "$spfs" | head -n 1)
printf '📧 SPF for %s\n   %s\n' "$domain" "$record"
if (( count > 1 )); then
  printf '   ⚠️  %d SPF records found. A domain must have one.\n' "$count"
fi

qualifier='no all mechanism'
for token in $record; do
  case "$token" in
    -all) qualifier='-all (hard fail)' ;;
    ~all) qualifier='~all (soft fail)' ;;
    +all) qualifier='+all (passes everything, unsafe)' ;;
    ?all) qualifier='?all (neutral)' ;;
  esac
done

lookups=0
includes=""
for token in $record; do
  case "$token" in
    include:*|a|a:*|mx|mx:*|ptr|ptr:*|exists:*|redirect=*)
      lookups=$(( lookups + 1 ))
      case "$token" in include:*) includes="$includes ${token#include:}" ;; esac
      ;;
  esac
done

printf '   Policy:   %s\n' "$qualifier"
printf '   Lookups:  %d (the limit is 10)\n' "$lookups"
if [[ -n $includes ]]; then
  printf '   Includes:%s\n' "$includes"
fi
if (( lookups > 10 )); then
  printf '   ⚠️  Too many lookups. Some receivers will fail the check.\n'
fi
