#!/usr/bin/env bash
set -euo pipefail

# Show the days left on a TLS certificate.
# Usage: tls-expiry.sh <host> [port]
# Needs: openssl

usage() {
  printf 'Usage: %s <host> [port]\n  host  A name or an address. The default port is 443.\n' "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi
if [[ $# -lt 1 || -z ${1:-} ]]; then
  usage >&2
  exit 1
fi

die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}
command -v openssl > /dev/null 2>&1 || die 'openssl is not installed.'

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
[[ $host =~ ^[A-Za-z0-9._-]+$ ]] || die "\"$host\" is not a valid host."
[[ $port =~ ^[0-9]+$ ]] || die "\"$port\" is not a valid port."

cert=$(openssl s_client -connect "$host:$port" -servername "$host" < /dev/null 2> /dev/null) || cert=""
[[ $cert == *"BEGIN CERTIFICATE"* ]] || die "no certificate from $host:$port."

subject=$(printf '%s\n' "$cert" | openssl x509 -noout -subject 2> /dev/null | sed 's/^subject=//') || subject=""
end=$(printf '%s\n' "$cert" | openssl x509 -noout -enddate 2> /dev/null | cut -d= -f2) || end=""
[[ -n $end ]] || die 'cannot read the expiry date.'
end=$(printf '%s' "$end" | tr -s ' ')
end=${end% GMT}
if date -j -f '%b %d %H:%M:%S %Y' "$end" +%s > /dev/null 2>&1; then
  epoch=$(date -j -f '%b %d %H:%M:%S %Y' "$end" +%s)
else
  epoch=$(date -u -d "$end" +%s)
fi

current=$(date +%s)
days=$(((epoch - current) / 86400))
printf '🔐 %s:%s\n   %s\n   Expires: %s\n' "$host" "$port" "$subject" "$end"
if ((epoch <= current)); then
  printf '   ❌ The certificate has expired.\n'
elif ((days < 30)); then
  printf '   ⚠️  %d days left. Renew it soon.\n' "$days"
else
  printf '   ✅ %d days left.\n' "$days"
fi
