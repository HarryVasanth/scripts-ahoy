#!/usr/bin/env bash
set -euo pipefail

# Fetch and explain a domain's DMARC record.
# Usage: dmarc-check.sh <domain>
# Needs: dig

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
command -v dig > /dev/null 2>&1 \
  || {
    printf 'Error: dig is not installed. Try: brew install bind or apt install dnsutils.\n' >&2
    exit 1
  }

domain=$1
[[ $domain =~ ^[A-Za-z0-9._-]+$ ]] \
  || {
    printf 'Error: "%s" is not a valid domain.\n' "$domain" >&2
    exit 1
  }

records=$(dig +short TXT "_dmarc.$domain" 2> /dev/null | tr -d '"' | grep -i '^v=DMARC1') || records=""
count=$(printf '%s\n' "$records" | awk 'NF { n++ } END { print n + 0 }')
if ((count == 0)); then
  printf '❌ No DMARC record at _dmarc.%s.\n' "$domain"
  exit 1
fi
record=$(printf '%s\n' "$records" | head -n 1)
printf '🛡️  DMARC for %s\n   %s\n' "$domain" "$record"
if ((count > 1)); then
  printf '   ⚠️  %d DMARC records found. A domain must have one.\n' "$count"
fi

policy="" sub="" pct="" rua="" ruf=""
oldifs=$IFS
IFS=';'
for part in $record; do
  part=$(printf '%s' "$part" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  key=${part%%=*}
  value=${part#*=}
  case "$key" in
    p) policy=$value ;;
    sp) sub=$value ;;
    pct) pct=$value ;;
    rua) rua=$value ;;
    ruf) ruf=$value ;;
  esac
done
IFS=$oldifs

case "$policy" in
  none) meaning='none (monitor only)' ;;
  quarantine) meaning='quarantine (send to spam)' ;;
  reject) meaning='reject (block)' ;;
  *) meaning='missing or unknown' ;;
esac
printf '   Policy:   %s\n' "$meaning"
[[ -z $sub ]] || printf '   Subdomain policy: %s\n' "$sub"
[[ -z $pct ]] || printf '   Applied to:       %s%% of mail\n' "$pct"
[[ -z $rua ]] || printf '   Reports to:       %s\n' "$rua"
[[ -z $ruf ]] || printf '   Failure reports:  %s\n' "$ruf"

if [[ $policy == none ]]; then
  printf '   ℹ️  Mail is not blocked. Move to quarantine when the reports look clean.\n'
fi
if [[ -n $pct && $pct != 100 ]]; then
  printf '   ⚠️  The policy does not cover all mail.\n'
fi
