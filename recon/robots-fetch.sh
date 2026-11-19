#!/usr/bin/env bash
set -euo pipefail

# Fetch and summarise a site's robots.txt file.
# Usage: robots-fetch.sh [--full] <url-or-host>
# Needs: curl

usage() {
  printf 'Usage: %s [--full] <url-or-host>\n  --full  Print the complete file.\n' "${0##*/}"
}
full=0
args=()
for arg in "$@"; do
  case "$arg" in
    -h | --help)
      usage
      exit 0
      ;;
    --full) full=1 ;;
    -*)
      printf 'Error: unknown option "%s".\n' "$arg" >&2
      exit 1
      ;;
    *) args+=("$arg") ;;
  esac
done
if ((${#args[@]} < 1)); then
  usage >&2
  exit 1
fi
command -v curl > /dev/null 2>&1 || {
  printf 'Error: curl is not installed.\n' >&2
  exit 1
}

target=${args[0]}
scheme=""
case "$target" in
  http://*)
    scheme=http
    rest=${target#http://}
    ;;
  https://*)
    scheme=https
    rest=${target#https://}
    ;;
  *) rest=$target ;;
esac
host=${rest%%/*}
[[ $host =~ ^[A-Za-z0-9._:-]+$ ]] \
  || {
    printf 'Error: "%s" is not a valid host.\n' "$host" >&2
    exit 1
  }

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
url=""
code=000
if [[ -n $scheme ]]; then
  url="$scheme://$host/robots.txt"
  code=$(curl -sS -L --max-time 10 -A 'robots-check/1.0' -o "$tmp" -w '%{http_code}' "$url") || code=000
else
  for scheme in https http; do
    url="$scheme://$host/robots.txt"
    code=$(curl -sS -L --max-time 10 -A 'robots-check/1.0' -o "$tmp" -w '%{http_code}' "$url") || code=000
    if [[ $code == 200 ]]; then break; fi
  done
fi

if [[ $code != 200 ]]; then
  printf '❌ No robots.txt at %s (HTTP %s).\n   Crawlers may then read all open paths.\n' "$url" "$code"
  exit 1
fi
printf '🤖 %s\n' "$url"
if ((full == 1)); then
  sed 's/\r$//' "$tmp" | sed 's/^/   /'
  exit 0
fi

sitemaps=$(grep -i '^sitemap:' "$tmp" | sed 's/^[^:]*:[[:space:]]*//; s/\r$//' || true)
delay=$(grep -i '^crawl-delay:' "$tmp" | sed 's/^[^:]*:[[:space:]]*//; s/\r$//' | head -1 || true)
disallow=$(grep -ci '^disallow:' "$tmp" || true)
allow=$(grep -ci '^allow:' "$tmp" || true)
if [[ -n $sitemaps ]]; then
  printf '   🗺️  Sitemaps:\n'
  printf '%s\n' "$sitemaps" | sed 's/^/      /'
fi
if [[ -n $delay ]]; then printf '   🐢 Crawl delay: %s\n' "$delay"; fi
printf '   🚫 Disallow rules: %s\n   ✅ Allow rules:    %s\n   Tip: use --full to see every rule.\n' \
  "$disallow" "$allow"
