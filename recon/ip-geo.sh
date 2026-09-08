#!/usr/bin/env bash
set -euo pipefail

# Show the location and network owner of an IP address.
# Usage: ip-geo.sh [ip...]
# Needs: curl
# Note: Uses the free ipinfo.io service. It may rate-limit. A fallback is used.

usage() {
  printf 'Usage: %s [ip...]\n  With no address, the script looks up your public address.\n' "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then usage; exit 0; fi
command -v curl >/dev/null 2>&1 || { printf 'Error: curl is not installed.\n' >&2; exit 1; }

json_field() {
  printf '%s' "$1" | tr ',' '\n' | grep -i "\"$2\"" | head -1 \
    | sed 's/^[^:]*:[[:space:]]*//; s/^"//; s/"$//' || true
}
show() { [[ -z $2 ]] || printf '   %-9s%s\n' "$1" "$2"; }

addresses=("$@")
if (( ${#addresses[@]} == 0 )); then
  addresses=("")
fi

ok=0
for ip in "${addresses[@]}"; do
  if [[ -n $ip && ! $ip =~ ^[0-9A-Fa-f:.]+$ ]]; then
    printf 'Error: "%s" is not an IP address.\n' "$ip" >&2
    continue
  fi
  json=""
  provider=""
  if [[ -n $ip ]]; then
    if json=$(curl -fsS --max-time 8 "https://ipinfo.io/$ip/json" 2>/dev/null); then
      provider='ipinfo.io'
    fi
    if [[ -z $json ]] && json=$(curl -fsS --max-time 8 \
      "http://ip-api.com/json/$ip?fields=status,country,regionName,city,isp,org,as,query" 2>/dev/null); then
      provider='ip-api.com'
    fi
  else
    if json=$(curl -fsS --max-time 8 "https://ipinfo.io/json" 2>/dev/null); then
      provider='ipinfo.io'
      ip=$(json_field "$json" ip)
    fi
  fi
  if [[ -z $json ]]; then
    printf '⚠️  No data for %s. The service may be rate-limiting you.\n' "${ip:-your address}" >&2
    continue
  fi
  if [[ $json == *'"bogon":true'* ]]; then
    printf '🏠 %s is a private or reserved address.\n' "$ip"
    ok=$(( ok + 1 ))
    continue
  fi

  city=$(json_field "$json" city)
  region=$(json_field "$json" region)
  [[ -n $region ]] || region=$(json_field "$json" regionName)
  country=$(json_field "$json" country)
  org=$(json_field "$json" org)
  [[ -n $org ]] || org=$(json_field "$json" isp)
  asn=$(json_field "$json" as)
  hostname=$(json_field "$json" hostname)
  place=$(printf '%s, %s, %s' "$city" "$region" "$country" | sed 's/^, //; s/, , /, /g; s/, $//')

  if [[ -z $city && -z $country && -z $org ]]; then
    printf '⚠️  No data for %s. The service may be rate-limiting you.\n' "$ip" >&2
    continue
  fi
  printf '🌍 %s\n' "$ip"
  show 'Place:' "$place"
  show 'Network:' "$org"
  show 'ASN:' "$asn"
  show 'Host:' "$hostname"
  printf '   Source:  %s\n' "$provider"
  ok=$(( ok + 1 ))
done
(( ok > 0 )) || exit 1
