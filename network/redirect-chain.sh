#!/usr/bin/env bash
set -euo pipefail

# Show each redirect hop and the final URL for a link.
# Usage: redirect-chain.sh <url> [max-hops]
# Needs: curl

usage() {
  printf 'Usage: %s <url> [max-hops]\n  max-hops  Stop after this many hops. Default: 10\n' "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then usage; exit 0; fi
if [[ $# -lt 1 || -z ${1:-} ]]; then usage >&2; exit 1; fi
command -v curl >/dev/null 2>&1 || { printf 'Error: curl is not installed.\n' >&2; exit 1; }

url=$1
max=${2:-10}
[[ $max =~ ^[1-9][0-9]*$ ]] || { printf 'Error: max-hops must be a positive number.\n' >&2; exit 1; }
case "$url" in
  http://*|https://*) ;;
  *) printf 'Error: give a URL that starts with http:// or https://.\n' >&2; exit 1 ;;
esac

printf '🔗 %s\n' "$url"
final=0
for (( hop = 1; hop <= max; hop++ )); do
  if ! out=$(curl -sS -o /dev/null --max-time 10 -w '%{http_code} %{redirect_url}' "$url"); then
    printf 'Error: cannot reach "%s".\n' "$url" >&2
    exit 1
  fi
  read -r code next <<< "$out"
  if [[ -n $next ]]; then
    printf '   %d. %s → %s\n' "$hop" "$code" "$next"
    url=$next
  else
    printf '   %d. %s (final)\n' "$hop" "$code"
    final=1
    break
  fi
done

if (( final == 0 )); then
  printf '⚠️  Stopped after %d hops. The chain may be longer.\n' "$max" >&2
fi
printf '📍 Final URL: %s\n' "$url"
