#!/usr/bin/env bash
set -euo pipefail

# Collect email addresses from public web pages.
# Usage: email-harvest.sh <url> [url...]
# Needs: curl
# Note: Use this on sites that you may inspect. The script does not crawl.

usage() {
  printf 'Usage: %s <url> [url...]\n' "${0##*/}"
  printf 'Example: %s https://example.com/contact\n' "${0##*/}"
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi
if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi
if ! command -v curl > /dev/null 2>&1; then
  printf 'Error: curl is not installed.\n' >&2
  exit 1
fi

page=$(mktemp)
out=$(mktemp)
trap 'rm -f "$page" "$out"' EXIT
: > "$out"

for url in "$@"; do
  case "$url" in
    http://* | https://*) ;;
    *)
      printf 'Error: "%s" is not an http or https URL.\n' "$url" >&2
      exit 1
      ;;
  esac
  if curl -sS -L --max-time 15 -A 'Mozilla/5.0 (email-check)' -o "$page" "$url"; then
    grep -Eoi '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$page" >> "$out" || true
  else
    printf '⚠️  Cannot fetch %s.\n' "$url" >&2
  fi
done

if [[ ! -s $out ]]; then
  printf '📭 No email addresses found.\n'
  exit 0
fi

result=$(tr '[:upper:]' '[:lower:]' < "$out" | sed 's/[.,;:]$//' | grep -Evi '\.(png|jpe?g|gif|svg|webp|css|js)$' | sort -u || true)
if [[ -z $result ]]; then
  printf '📭 No email addresses found.\n'
  exit 0
fi
count=$(printf '%s\n' "$result" | wc -l | tr -d ' ')
printf '📧 %d unique addresses\n' "$count"
printf '%s\n' "$result" | sed 's/^/   /'
