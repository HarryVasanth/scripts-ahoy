#!/usr/bin/env bash
set -euo pipefail

# Summarise the registration data of a domain.
# Usage: whois-summary.sh <domain>
# Needs: whois

usage() {
  printf 'Usage: %s <domain>\nExample: %s example.com\n' "${0##*/}" "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then usage; exit 0; fi
if [[ $# -lt 1 || -z ${1:-} ]]; then usage >&2; exit 1; fi
command -v whois >/dev/null 2>&1 \
  || { printf 'Error: whois is not installed. Try: brew install whois or apt install whois.\n' >&2; exit 1; }

domain=$1
[[ $domain =~ ^[A-Za-z0-9._-]+$ ]] \
  || { printf 'Error: "%s" is not a valid domain.\n' "$domain" >&2; exit 1; }

data=$(whois "$domain" 2>/dev/null) || data=""
if [[ -z $data ]]; then
  printf 'Error: whois gave no answer for "%s".\n' "$domain" >&2
  exit 1
fi
if printf '%s\n' "$data" | grep -qiE 'rate limit|quota exceeded|too many requests'; then
  printf 'Error: the whois service is rate-limiting you. Try again later.\n' >&2
  exit 1
fi
if ! printf '%s\n' "$data" | grep -qiE '^(registrar|name server):'; then
  tld=${domain##*.}
  refer=$(whois -h whois.iana.org "$tld" 2>/dev/null | awk 'tolower($1) == "refer:" || tolower($1) == "whois:" { print $2; exit }')
  if [[ -n $refer ]]; then
    data=$(whois -h "$refer" "$domain" 2>/dev/null) || data=""
  fi
fi

field() {
  printf '%s\n' "$data" | awk -v key="$1" '
    { line = tolower($0); sub(/^[ \t]+/, "", line); wanted = tolower(key) ":" }
    index(line, wanted) == 1 {
      sub(/^[^:]*:[ \t]*/, ""); sub(/\r$/, ""); print; exit
    }'
}

first_field() {
  local value
  for key in "$@"; do
    value=$(field "$key")
    if [[ -n $value ]]; then printf '%s' "$value"; return 0; fi
  done
}

registrar=$(first_field "Registrar")
created=$(first_field "Creation Date" "Created" "Created On")
expires=$(first_field "Registry Expiry Date" "Expiry Date" "Expiration Date")
updated=$(first_field "Updated Date" "Last Updated")
status=$(first_field "Domain Status" "Status")

show() { [[ -z $2 ]] || printf '   %-12s %s\n' "$1" "$2"; }
printf '📇 %s\n' "$domain"
show 'Registrar:' "$registrar"
show 'Created:' "$created"
show 'Expires:' "$expires"
show 'Updated:' "$updated"
show 'Status:' "$status"

servers=$(printf '%s\n' "$data" | awk '
  { line = tolower($0); sub(/^[ \t]+/, "", line) }
  index(line, "name server:") == 1 || index(line, "nameserver:") == 1 {
    sub(/^[^:]*:[ \t]*/, ""); sub(/\r$/, ""); print
  }' | head -6)
if [[ -n $servers ]]; then
  printf '   Name servers:\n'
  printf '%s\n' "$servers" | sed 's/^/      /'
fi

if [[ -z $registrar && -z $created && -z $expires && -z $servers ]]; then
  printf '   No registration data. The domain may be free.\n'
  exit 1
fi
