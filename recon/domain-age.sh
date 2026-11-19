#!/usr/bin/env bash
set -euo pipefail

# Show a domain's creation date and its age from whois data.
# Usage: domain-age.sh <domain>
# Needs: whois

usage() {
  printf 'Usage: %s <domain>\nExample: %s example.com\n' "${0##*/}" "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi
if [[ $# -lt 1 || -z ${1:-} ]]; then
  usage >&2
  exit 1
fi
command -v whois > /dev/null 2>&1 \
  || {
    printf 'Error: whois is not installed. Try: brew install whois or apt install whois.\n' >&2
    exit 1
  }

domain=$1
[[ $domain =~ ^[A-Za-z0-9._-]+$ ]] \
  || {
    printf 'Error: "%s" is not a valid domain.\n' "$domain" >&2
    exit 1
  }

data=$(whois "$domain" 2> /dev/null) || data=""
created=$(printf '%s\n' "$data" | awk '
  { line = tolower($0); sub(/^[ \t]+/, "", line) }
  index(line, "creation date:") == 1 || index(line, "created on:") == 1 ||
  index(line, "created:") == 1 || index(line, "registered on:") == 1 {
    sub(/^[^:]*:[ \t]*/, ""); sub(/\r$/, ""); print; exit
  }')
if [[ -z $created ]]; then
  printf '❌ No creation date for %s in the whois data.\n' "$domain" >&2
  exit 1
fi

day=${created%%T*}
day=${day%%.*}
day=${day%% *}
epoch=""
for fmt in '%Y-%m-%d' '%d-%b-%Y' '%Y.%m.%d' '%d/%m/%Y' '%Y/%m/%d'; do
  if epoch=$(date -j -f "$fmt" "$day" +%s 2> /dev/null); then break; fi
done
if [[ -z $epoch ]]; then
  epoch=$(date -d "$day" +%s 2> /dev/null) || epoch=""
fi
if [[ -z $epoch ]]; then
  printf '❌ Cannot read the creation date "%s".\n' "$created" >&2
  exit 1
fi

days=$((($(date +%s) - epoch) / 86400))
printf '📅 %s\n   Created: %s\n   Age:     %d years, %d days (%d days)\n' \
  "$domain" "$created" "$((days / 365))" "$((days % 365))" "$days"
