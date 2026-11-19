#!/usr/bin/env bash
set -euo pipefail

# Fetch sitemap.xml and list the URLs that it contains.
# Usage: sitemap-fetch.sh <url-or-host>
# Needs: curl

usage() {
  printf 'Usage: %s <url-or-host>\nExample: %s example.com\n' "${0##*/}" "${0##*/}"
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

target=$1
case "$target" in
  http://* | https://*) url=$target ;;
  *)
    host=${target%%/*}
    [[ $host =~ ^[A-Za-z0-9._:-]+$ ]] \
      || {
        printf 'Error: "%s" is not a valid host.\n' "$host" >&2
        exit 1
      }
    url="https://$host/sitemap.xml"
    ;;
esac

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
page="$dir/sitemap.xml"
if ! curl -sS -L --max-time 20 -A 'sitemap-fetch/1.0' -o "$page" "$url"; then
  url=${url/https:/http:}
  curl -sS -L --max-time 20 -A 'sitemap-fetch/1.0' -o "$page" "$url" \
    || {
      printf 'Error: cannot fetch %s.\n' "$url" >&2
      exit 1
    }
fi
if [[ ! -s $page ]]; then
  printf '❌ The sitemap is empty: %s\n' "$url" >&2
  exit 1
fi

extract() {
  grep -o '<loc>[^<]*</loc>' "$1" 2> /dev/null \
    | sed 's/<[^>]*>//g; s/^[[:space:]]*//; s/[[:space:]]*$//'
}

all="$dir/all.txt"
: > "$all"
if grep -qi '<sitemapindex' "$page"; then
  extract "$page" | head -n 10 > "$dir/children.txt"
  printf '🗺️  Sitemap index: %s\n' "$url"
  while IFS= read -r child; do
    [[ -n $child ]] || continue
    curl -sS -L --max-time 20 -o "$dir/child.xml" "$child" || continue
    extract "$dir/child.xml" >> "$all"
  done < "$dir/children.txt"
else
  printf '🗺️  Sitemap: %s\n' "$url"
  extract "$page" >> "$all"
fi

sort -u "$all" | sed '/^$/d' > "$dir/urls.txt"
count=$(wc -l < "$dir/urls.txt" | tr -d ' ')
if ((count == 0)); then
  printf '❌ No URLs found in the sitemap.\n' >&2
  exit 1
fi
sed 's/^/   /' "$dir/urls.txt"
printf '📊 %s URLs.\n' "$count"
