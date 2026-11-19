#!/usr/bin/env bash
set -euo pipefail

# Show response headers and check common security headers.
# Usage: http-headers.sh <url>
# Needs: curl

usage() {
  printf 'Usage: %s <url>\n' "${0##*/}"
  printf 'Example: %s https://example.com\n' "${0##*/}"
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi
if [[ $# -lt 1 || -z ${1:-} ]]; then
  usage >&2
  exit 1
fi
if ! command -v curl > /dev/null 2>&1; then
  printf 'Error: curl is not installed.\n' >&2
  exit 1
fi

url=$1
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

if ! code=$(curl -sS -L --max-time 15 -D "$tmp" -o /dev/null -w '%{http_code}' "$url"); then
  printf 'Error: cannot reach "%s".\n' "$url" >&2
  exit 1
fi

header() {
  awk -v want="$1" '
    { line = tolower($0); key = tolower(want) ":" }
    index(line, key) == 1 {
      sub(/^[^:]*:[ \t]*/, "")
      sub(/\r$/, "")
      value = $0
    }
    END { print value }
  ' "$tmp"
}

printf '📋 %s (HTTP %s)\n' "$url" "$code"
awk '{ sub(/\r$/, ""); if (length($0) > 0) printf "   %s\n", $0 }' "$tmp"

printf '🛡️  Security headers\n'
for name in strict-transport-security content-security-policy x-frame-options x-content-type-options referrer-policy; do
  value=$(header "$name")
  if [[ -n $value ]]; then
    printf '   ✅ %s\n' "$name"
  else
    printf '   ❌ %s is missing\n' "$name"
  fi
done
