#!/usr/bin/env bash
set -euo pipefail

# Show DNS, connect, TLS, and first-byte timing for a URL.
# Usage: http-timing.sh <url>
# Needs: curl, awk

usage() {
  printf 'Usage: %s <url>\nExample: %s https://example.com\n' "${0##*/}" "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then usage; exit 0; fi
if [[ $# -lt 1 || -z ${1:-} ]]; then usage >&2; exit 1; fi
command -v curl >/dev/null 2>&1 || { printf 'Error: curl is not installed.\n' >&2; exit 1; }

url=$1
case "$url" in
  http://*|https://*) ;;
  *) printf 'Error: give a URL that starts with http:// or https://.\n' >&2; exit 1 ;;
esac

if ! times=$(curl -sS -L -o /dev/null --max-time 30 \
  -w '%{time_namelookup} %{time_connect} %{time_appconnect} %{time_starttransfer} %{time_total}' "$url"); then
  printf 'Error: cannot reach "%s".\n' "$url" >&2
  exit 1
fi
read -r dns connect tls ttfb total <<< "$times"

awk -v url="$url" -v dns="$dns" -v connect="$connect" \
    -v tls="$tls" -v ttfb="$ttfb" -v total="$total" 'BEGIN {
  base = (tls > 0) ? tls : connect
  printf "⏱️  %s\n", url
  printf "   DNS lookup:    %7.1f ms\n", dns * 1000
  printf "   TCP connect:   %7.1f ms\n", (connect - dns) * 1000
  if (tls > 0) printf "   TLS handshake: %7.1f ms\n", (tls - connect) * 1000
  else printf "   TLS handshake:     n/a\n"
  printf "   First byte:    %7.1f ms\n", (ttfb - base) * 1000
  printf "   Total:         %7.1f ms\n", total * 1000
}'
