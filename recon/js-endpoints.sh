#!/usr/bin/env bash
set -euo pipefail

# Extract URLs and paths from JavaScript files.
# Usage: js-endpoints.sh <url> [url...]
# Needs: curl

usage() {
  printf 'Usage: %s <url> [url...]\n' "${0##*/}"
  printf '  Give one or more JavaScript files. The script prints unique URLs and paths.\n'
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then usage; exit 0; fi
if [[ $# -lt 1 ]]; then usage >&2; exit 1; fi
command -v curl >/dev/null 2>&1 || { printf 'Error: curl is not installed.\n' >&2; exit 1; }

found=$(mktemp)
trap 'rm -f "$found"' EXIT
for url in "$@"; do
  case "$url" in
    http://*|https://*) ;;
    *) printf '⚠️  Skip "%s". It is not an http or https URL.\n' "$url" >&2; continue ;;
  esac
  if ! body=$(curl -sS -L --max-time 20 -A 'js-endpoints/1.0' "$url"); then
    printf '⚠️  Cannot fetch %s.\n' "$url" >&2
    continue
  fi
  printf '%s\n' "$body" \
    | grep -oE "https?://[^\"' )<>]+" \
    | sed 's/[,.;:]$//' >> "$found" || true
  printf '%s\n' "$body" \
    | grep -oE "[\"']/[A-Za-z0-9._~/?=&%+-]{2,}[\"']" \
    | sed "s/^.//; s/.$//" >> "$found" || true
done

sort -u -o "$found" "$found"
count=$(wc -l < "$found" | tr -d ' ')
if (( count == 0 )); then
  printf '❌ No URLs or paths found.\n' >&2
  exit 1
fi
printf '🔗 Endpoints found: %s\n' "$count"
sed 's/^/   /' "$found"
