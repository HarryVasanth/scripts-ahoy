#!/usr/bin/env bash
set -euo pipefail

# List archived URLs for a domain from the Wayback Machine.
# Usage: wayback-urls.sh <domain> [limit]
# Needs: curl

usage() {
  printf 'Usage: %s <domain> [limit]\n' "${0##*/}"
  printf '  limit  Highest number of URLs to return. Default: 50, maximum: 1000\n'
  printf 'Example: %s example.com 100\n' "${0##*/}"
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

domain=$1
domain=${domain#http://}
domain=${domain#https://}
domain=${domain%%/*}
limit=${2:-50}
if [[ ! $domain =~ ^[A-Za-z0-9._-]+$ ]]; then
  printf 'Error: "%s" is not a valid domain.\n' "$domain" >&2
  exit 1
fi
if [[ ! $limit =~ ^[0-9]+$ ]] || (( limit < 1 || limit > 1000 )); then
  printf 'Error: the limit must be from 1 to 1000.\n' >&2
  exit 1
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
api="https://web.archive.org/cdx/search/cdx?url=${domain}/*&output=txt&fl=original&collapse=urlkey&limit=${limit}"

if ! code=$(curl -sS -L --max-time 30 -o "$tmp" -w '%{http_code}' "$api"); then
  printf 'Error: the Wayback Machine did not answer.\n' >&2
  exit 1
fi
case "$code" in
  200) ;;
  429)
    printf 'Error: the Wayback Machine is rate-limiting you. Try again later.\n' >&2
    exit 1
    ;;
  *)
    printf 'Error: the Wayback Machine answered with HTTP %s.\n' "$code" >&2
    exit 1
    ;;
esac

if [[ ! -s $tmp ]]; then
  printf '📭 No archived URLs for %s.\n' "$domain"
  exit 0
fi

count=$(wc -l < "$tmp" | tr -d ' ')
printf '📚 %d archived URLs for %s\n' "$count" "$domain"
sed 's/\r$//' "$tmp" | sed 's/^/   /'
