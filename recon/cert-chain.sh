#!/usr/bin/env bash
set -euo pipefail

# Print the full TLS certificate chain that a server sends.
# Usage: cert-chain.sh <host> [port]
# Needs: openssl

usage() {
  printf 'Usage: %s <host> [port]\n  port  The default port is 443.\n' "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then usage; exit 0; fi
if [[ $# -lt 1 || -z ${1:-} ]]; then usage >&2; exit 1; fi
command -v openssl >/dev/null 2>&1 || { printf 'Error: openssl is not installed.\n' >&2; exit 1; }

host=$1
port=${2:-443}
host=${host#https://}
host=${host%%/*}
[[ $host =~ ^[A-Za-z0-9._-]+$ ]] \
  || { printf 'Error: "%s" is not a valid host.\n' "$host" >&2; exit 1; }
[[ $port =~ ^[0-9]+$ ]] \
  || { printf 'Error: "%s" is not a valid port.\n' "$port" >&2; exit 1; }
(( port >= 1 && port <= 65535 )) \
  || { printf 'Error: "%s" is not a valid port.\n' "$port" >&2; exit 1; }

pem=$(openssl s_client -connect "$host:$port" -servername "$host" -showcerts </dev/null 2>/dev/null) || pem=""
if [[ $pem != *"BEGIN CERTIFICATE"* ]]; then
  printf '❌ No certificate from %s:%s.\n' "$host" "$port" >&2
  exit 1
fi

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
printf '%s\n' "$pem" | awk -v dir="$dir" '
  /BEGIN CERTIFICATE/ { n++; file = dir "/cert-" n ".pem" }
  file != "" { print > file }
  /END CERTIFICATE/ { file = "" }
'

printf '🔗 Chain from %s:%s\n' "$host" "$port"
count=0
for cert in "$dir"/cert-*.pem; do
  [[ -e $cert ]] || break
  count=$(( count + 1 ))
  subject=$(openssl x509 -in "$cert" -noout -subject 2>/dev/null | sed 's/^subject=//; s/^ *//')
  issuer=$(openssl x509 -in "$cert" -noout -issuer 2>/dev/null | sed 's/^issuer=//; s/^ *//')
  printf '   %d. %s\n      Issuer: %s\n' "$count" "$subject" "$issuer"
done
if (( count < 2 )); then
  printf '   ⚠️  The server sent one certificate. It may omit the intermediate.\n'
fi
