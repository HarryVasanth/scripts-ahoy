#!/usr/bin/env bash
set -euo pipefail

# Check a site for a security.txt file and show its key fields.
# Usage: security-txt.sh <domain>
# Needs: curl

usage() {
  printf 'Usage: %s <domain>\n' "${0##*/}"
  printf 'Example: %s example.com\n' "${0##*/}"
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi
if [[ $# -lt 1 || -z ${1:-} ]]; then
  usage >&2
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  printf 'Error: curl is not installed.\n' >&2
  exit 1
fi

target=$1
target=${target#http://}
target=${target#https://}
host=${target%%/*}
if [[ ! $host =~ ^[A-Za-z0-9._:-]+$ ]]; then
  printf 'Error: "%s" is not a valid host.\n' "$host" >&2
  exit 1
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

url=""
code=000
for scheme in https http; do
  url="$scheme://$host/.well-known/security.txt"
  code=$(curl -sS -L --max-time 10 -A 'security-txt-check/1.0' -o "$tmp" -w '%{http_code}' "$url") || code=000
  if [[ $code == 200 ]]; then
    break
  fi
done

if [[ $code != 200 ]]; then
  printf '❌ No security.txt at %s (HTTP %s).\n' "$url" "$code"
  printf '   Publish one at /.well-known/security.txt. See RFC 9116.\n'
  exit 1
fi

printf '🔐 %s\n' "$url"
fields=$(grep -iE '^(contact|expires|canonical|policy|encryption|preferred-languages|acknowledgments|hiring|csaf):' "$tmp" | sed 's/\r$//' || true)
if [[ -z $fields ]]; then
  printf '   ⚠️  The file has no standard fields.\n'
  exit 1
fi
printf '%s\n' "$fields" | sed 's/^/   /'

contacts=$(printf '%s\n' "$fields" | grep -ci '^contact:' || true)
if (( contacts == 0 )); then
  printf '   ⚠️  No Contact field. RFC 9116 requires one.\n'
fi

expires=$(grep -i '^expires:' "$tmp" | head -1 | cut -d: -f2- | tr -d ' \r' || true)
if [[ -n $expires ]]; then
  today=$(date -u +%Y-%m-%d)
  if [[ $expires < $today ]]; then
    printf '   ⚠️  The file expired on %s.\n' "$expires"
  else
    printf '   ✅ Valid until %s\n' "$expires"
  fi
else
  printf '   ⚠️  No Expires field. RFC 9116 requires one.\n'
fi
