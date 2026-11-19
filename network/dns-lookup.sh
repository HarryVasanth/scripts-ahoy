#!/usr/bin/env bash
set -euo pipefail

# Look up DNS records for a name.
# Usage: dns-lookup.sh <name> [type] [resolver]
# Needs: dig (macOS: brew install bind, Debian: apt install dnsutils)

usage() {
  printf 'Usage: %s <name> [type] [resolver]\n' "${0##*/}"
  printf '  type      One of A, AAAA, MX, TXT, NS, CNAME, SOA, SRV, CAA, ANY.\n'
  printf '            The default is A and AAAA.\n'
  printf '  resolver  Name server to ask. Example: 1.1.1.1\n'
  printf 'Example: %s example.com MX 1.1.1.1\n' "${0##*/}"
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi
if [[ $# -lt 1 || -z ${1:-} ]]; then
  usage >&2
  exit 1
fi

if ! command -v dig > /dev/null 2>&1; then
  printf 'Error: dig is not installed.\n' >&2
  printf 'Install it: brew install bind (macOS) or apt install dnsutils (Debian).\n' >&2
  exit 1
fi

name=$1
type=${2:-}
resolver=${3:-}
types=()

case "$name" in
  *[!A-Za-z0-9._-]*)
    printf 'Error: "%s" is not a valid host name.\n' "$name" >&2
    exit 1
    ;;
esac

if [[ -z $type ]]; then
  types=(A AAAA)
else
  type=$(printf '%s' "$type" | tr '[:lower:]' '[:upper:]')
  case "$type" in
    A | AAAA | MX | TXT | NS | CNAME | SOA | SRV | CAA) types=("$type") ;;
    ANY) types=(A AAAA MX TXT NS CNAME) ;;
    *)
      printf 'Error: unsupported record type "%s".\n' "$type" >&2
      exit 1
      ;;
  esac
fi

for record in "${types[@]}"; do
  if [[ -n $resolver ]]; then
    answer=$(dig +short +time=3 +tries=1 "@$resolver" "$name" "$record" 2> /dev/null) || answer=""
  else
    answer=$(dig +short +time=3 +tries=1 "$name" "$record" 2> /dev/null) || answer=""
  fi
  printf '🔎 %s %s\n' "$name" "$record"
  if [[ -z $answer ]]; then
    printf '   (no records)\n'
  else
    printf '%s\n' "$answer" | sed 's/^/   /'
  fi
done
