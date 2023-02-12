#!/usr/bin/env bash
set -euo pipefail

# Show the details of the TLS certificate that a server presents.
# Usage: cert-info.sh <host> [port]
# Needs: openssl

usage() {
  printf 'Usage: %s <host> [port]\n' "${0##*/}"
  printf '  host  A name or an address. The default port is 443.\n'
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi
if [[ $# -lt 1 || -z ${1:-} ]]; then
  usage >&2
  exit 1
fi
if ! command -v openssl >/dev/null 2>&1; then
  printf 'Error: openssl is not installed.\n' >&2
  exit 1
fi

target=$1
target=${target#https://}
target=${target%%/*}
port=${2:-443}
case "$target" in
  *:*)
    port=${target##*:}
    host=${target%:*}
    ;;
  *) host=$target ;;
esac
if [[ ! $host =~ ^[A-Za-z0-9._-]+$ ]] || [[ ! $port =~ ^[0-9]+$ ]]; then
  printf 'Error: use a host name and an optional port.\n' >&2
  exit 1
fi

pem=$(openssl s_client -connect "$host:$port" -servername "$host" -showcerts </dev/null 2>/dev/null) || pem=""
if [[ $pem != *"BEGIN CERTIFICATE"* ]]; then
  printf 'Error: no certificate from %s:%s.\n' "$host" "$port" >&2
  exit 1
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
printf '%s\n' "$pem" | awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/' > "$tmp"

subject=$(openssl x509 -in "$tmp" -noout -subject 2>/dev/null | sed 's/^subject=//')
issuer=$(openssl x509 -in "$tmp" -noout -issuer 2>/dev/null | sed 's/^issuer=//')
serial=$(openssl x509 -in "$tmp" -noout -serial 2>/dev/null | cut -d= -f2)
dates=$(openssl x509 -in "$tmp" -noout -dates 2>/dev/null)
details=$(openssl x509 -in "$tmp" -noout -text 2>/dev/null)
algo=$(printf '%s\n' "$details" | awk '/Signature Algorithm/ { sub(/.*: /, ""); print; exit }')
bits=$(printf '%s\n' "$details" | awk '/Public-Key:/ { gsub(/[()]/, "", $2); print $2; exit }')
sans=$(printf '%s\n' "$details" | awk '/X509v3 Subject Alternative Name/ { getline; gsub(/^[ \t]+/, ""); print; exit }')

printf '🔏 %s:%s\n' "$host" "$port"
printf '   Subject:  %s\n' "$subject"
printf '   Issuer:   %s\n' "$issuer"
printf '%s\n' "$dates" | sed 's/^/   /'
if [[ -n $serial ]]; then printf '   Serial:   %s\n' "$serial"; fi
if [[ -n $algo ]]; then printf '   Signed:   %s\n' "$algo"; fi
if [[ -n $bits ]]; then printf '   Key:      %s bits\n' "$bits"; fi
if [[ -n $sans ]]; then
  printf '   Names:\n'
  printf '%s\n' "$sans" | tr ',' '\n' | sed 's/^[ \t]*//; s/^DNS://' | sed 's/^/      /'
else
  printf '   Names:    no subject alternative names\n'
fi
