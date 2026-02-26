#!/usr/bin/env bash
set -euo pipefail

# Detect the server and framework behind a web page.
# Usage: http-tech.sh <url>
# Needs: curl

usage() {
  printf 'Usage: %s <url>\nExample: %s https://example.com\n' "${0##*/}" "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then usage; exit 0; fi
if [[ $# -lt 1 || -z ${1:-} ]]; then usage >&2; exit 1; fi
command -v curl >/dev/null 2>&1 || { printf 'Error: curl is not installed.\n' >&2; exit 1; }

url=$1
headers=$(mktemp)
body=$(mktemp)
trap 'rm -f "$headers" "$body"' EXIT
code=$(curl -sS -L --max-time 15 -A 'Mozilla/5.0 (tech-check)' -D "$headers" -o "$body" \
  -w '%{http_code}' "$url") || { printf 'Error: cannot reach "%s".\n' "$url" >&2; exit 1; }

header() {
  awk -v want="$1" '{ line = tolower($0); key = tolower(want) ":" }
    index(line, key) == 1 { sub(/^[^:]*:[ \t]*/, ""); sub(/\r$/, ""); value = $0 }
    END { print value }' "$headers"
}
has() { grep -qi "$1" "$body"; }

found=()
add_header() {
  local value
  value=$(header "$1")
  [[ -z $value ]] || found+=("$1: $value")
}
add_header server
add_header x-powered-by

for pair in 'cf-ray:Cloudflare' 'x-shopify-stage:Shopify' 'x-vercel-id:Vercel' \
  'x-amz-cf-id:Amazon CloudFront' 'x-github-request-id:GitHub Pages'; do
  [[ -z $(header "${pair%%:*}") ]] || found+=("${pair#*:}")
done

if has 'wp-content\|wp-includes'; then found+=("WordPress"); fi
if has '__NEXT_DATA__'; then found+=("Next.js"); fi
if has '__NUXT__\|_nuxt/'; then found+=("Nuxt"); fi
if has 'ng-version\|ng-app'; then found+=("Angular"); fi
if has 'data-reactroot\|react-dom'; then found+=("React"); fi
if has 'csrfmiddlewaretoken'; then found+=("Django"); fi
if has 'laravel_session'; then found+=("Laravel"); fi
if has 'drupal-settings-json\|sites/default/files'; then found+=("Drupal"); fi
if has 'cdn.shopify.com'; then found+=("Shopify"); fi

printf '🔍 %s (HTTP %s)\n' "$url" "$code"
if (( ${#found[@]} == 0 )); then
  printf '   No clear markers found.\n'
else
  printf '   • %s\n' "${found[@]}"
fi
