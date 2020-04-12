#!/usr/bin/env bash
set -euo pipefail

# Probe which HTTP methods a URL allows.
# Usage: http-methods.sh [--yes] <url>
# Needs: curl
# Note: This sends write requests. Use it only on a URL that you own.

usage() {
  printf 'Usage: %s [--yes] <url>\n' "${0##*/}"
  printf '  --yes  Do not ask for confirmation.\n'
  printf '  The probe sends OPTIONS, HEAD, GET, POST, PUT, PATCH, DELETE, and TRACE.\n'
}

ask=1 args=()
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --yes) ask=0 ;;
    -*) printf 'Error: unknown option "%s". Try --help.\n' "$arg" >&2; exit 1 ;;
    *) args+=("$arg") ;;
  esac
done
if (( ${#args[@]} != 1 )); then usage >&2; exit 1; fi
url=${args[0]}
case "$url" in
  http://*|https://*) ;;
  *) printf 'Error: give a URL that starts with http:// or https://.\n' >&2; exit 1 ;;
esac
command -v curl >/dev/null 2>&1 || { printf 'Error: curl is not installed.\n' >&2; exit 1; }

printf '⚠️  This sends write requests (POST, PUT, PATCH, DELETE) to %s.\n' "$url" >&2
printf '   Use it only on a URL that you own.\n' >&2
if (( ask == 1 )); then
  printf 'Continue? [y/N] '
  read -r reply || reply=""
  case "$reply" in
    y|Y|yes|YES) ;;
    *) printf 'Cancelled.\n'; exit 1 ;;
  esac
fi

printf '🧪 Methods for %s\n' "$url"
for method in GET HEAD OPTIONS POST PUT PATCH DELETE TRACE; do
  code=$(curl -sS -o /dev/null --max-time 10 -X "$method" -w '%{http_code}' "$url") || code=000
  case "$code" in
    200|201|202|204|301|302|303|307|308) verdict='allowed' ;;
    401|403) verdict='needs auth' ;;
    405) verdict='not allowed' ;;
    501) verdict='not implemented' ;;
    000) verdict='no answer' ;;
    *) verdict='answered' ;;
  esac
  printf '   %-8s %s  %s\n' "$method" "$code" "$verdict"
done
