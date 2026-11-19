#!/usr/bin/env bash
set -euo pipefail

# Summarise the listening TCP and UDP sockets on this host.
# Usage: netstat-summary.sh
# Needs: ss, lsof, or netstat

usage() {
  printf 'Usage: %s\n  Shows the local listening sockets and a count.\n' "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

if command -v ss > /dev/null 2>&1; then
  tool=ss
  list=$(ss -lntu 2> /dev/null | awk 'NR > 1 { print $1, $5 }') || list=""
elif command -v lsof > /dev/null 2>&1; then
  tool=lsof
  list=$(lsof +c 15 -nP -iTCP -sTCP:LISTEN -iUDP 2> /dev/null \
    | awk 'NR > 1 {
        name = $NF
        if (name == "(LISTEN)") name = $(NF - 1)
        if (name != "*:*" && name !~ /->/) print $1, name
      }' | sed 's/\\x20/ /g' | sort -u) || list=""
elif command -v netstat > /dev/null 2>&1; then
  tool=netstat
  list=$(netstat -an 2> /dev/null \
    | awk '$1 ~ /^(tcp|udp)/ && ($NF == "LISTEN" || $1 ~ /^udp/) { print $1, $4 }') || list=""
else
  printf 'Error: no socket tool found. Install iproute2, lsof, or net-tools.\n' >&2
  exit 1
fi

printf '🔌 Listening sockets (via %s)\n' "$tool"
if [[ -z $list ]]; then
  printf '   No listening sockets found.\n'
  exit 0
fi
printf '%s\n' "$list" | sed 's/^/   /'
count=$(printf '%s\n' "$list" | awk 'NF { n++ } END { print n + 0 }')
printf '📊 %s sockets.\n' "$count"
