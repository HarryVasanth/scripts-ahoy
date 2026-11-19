#!/usr/bin/env bash
set -euo pipefail

# Check common HTTP security headers on a URL.
# Usage: security-headers.sh <url>
# Needs: curl

usage() {
  printf 'Usage: %s <url>\nExample: %s https://example.com\n' "${0##*/}" "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi
if [[ $# -lt 1 || -z ${1:-} ]]; then
  usage >&2
  exit 1
fi
command -v curl > /dev/null 2>&1 || {
  printf 'Error: curl is not installed.\n' >&2
  exit 1
}

url=$1
case "$url" in
  http://* | https://*) ;;
  *)
    printf 'Error: give a URL that starts with http:// or https://.\n' >&2
    exit 1
    ;;
esac

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
if ! code=$(curl -sS -L --max-time 15 -D "$tmp" -o /dev/null -w '%{http_code}' "$url"); then
  printf 'Error: cannot reach "%s".\n' "$url" >&2
  exit 1
fi

header() {
  awk -v want="$1" '
    { line = tolower($0); key = tolower(want) ":" }
    index(line, key) == 1 { sub(/^[^:]*:[ \t]*/, ""); sub(/\r$/, ""); value = $0 }
    END { print value }
  ' "$tmp"
}

missing=0
check() {
  value=$(header "$1")
  if [[ -n $value ]]; then
    printf '   ✅ %-28s %s\n' "$1" "$value"
  else
    printf '   ❌ %-28s missing\n' "$1"
    missing=$((missing + 1))
  fi
}

printf '🛡️  Security headers for %s (HTTP %s)\n' "$url" "$code"
check strict-transport-security
check content-security-policy
check x-frame-options
check x-content-type-options
check referrer-policy
check permissions-policy
check cross-origin-opener-policy

if [[ $url == http://* ]]; then
  printf '   ℹ️  This was plain HTTP. HSTS only applies over HTTPS.\n'
fi
printf '📊 Missing headers: %d of 7.\n' "$missing"
