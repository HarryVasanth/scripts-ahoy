#!/usr/bin/env bash
set -euo pipefail

# Ask several public resolvers for one DNS record and compare the answers.
# Usage: dns-propagation.sh <name> [type]
# Needs: dig (macOS: brew install bind, Debian: apt install dnsutils)

usage() {
  printf 'Usage: %s <name> [type]\n  type  A, AAAA, MX, NS, TXT, CNAME, or SOA. Default: A\n' "${0##*/}"
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

name=$1
type=${2:-A}
type=$(printf '%s' "$type" | tr '[:lower:]' '[:upper:]')
case "$type" in
  A | AAAA | MX | NS | TXT | CNAME | SOA) ;;
  *)
    printf 'Error: unsupported record type "%s".\n' "$type" >&2
    exit 1
    ;;
esac
[[ $name =~ ^[A-Za-z0-9._-]+$ ]] \
  || {
    printf 'Error: "%s" is not a valid name.\n' "$name" >&2
    exit 1
  }

resolvers=(1.1.1.1 8.8.8.8 9.9.9.9 208.67.222.222 64.6.64.6)
all=""
printf '🌍 %s %s\n' "$name" "$type"
for resolver in "${resolvers[@]}"; do
  answer=$(dig +short +time=3 +tries=1 "@$resolver" "$name" "$type" 2> /dev/null | sort | tr '\n' ' ')
  answer=${answer% }
  if [[ -z $answer ]]; then
    printf '   %-15s (no answer)\n' "$resolver"
  else
    printf '   %-15s %s\n' "$resolver" "$answer"
  fi
  all="$all|$answer"
done

unique=$(printf '%s\n' "$all" | tr '|' '\n' | sort -u | awk 'NF { n++ } END { print n + 0 }')
if ((unique <= 1)); then
  printf '✅ All resolvers agree.\n'
else
  printf '⚠️  Resolvers disagree. The change may still be in progress.\n'
fi
