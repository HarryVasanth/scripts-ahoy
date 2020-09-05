#!/usr/bin/env bash
set -euo pipefail
# Ping every address in a small block and list the replies.
# Usage: ping-sweep.sh [--yes] [--dry-run] <cidr>
# Needs: ping
# Note: Scan only networks that you own or have permission to test.

usage() {
  printf 'Usage: %s [--yes] [--dry-run] <cidr>\n  cidr       A /24 to /30 block. Example: 192.168.1.0/24\n  --yes      Do not ask for confirmation.\n  --dry-run  Show the plan. Send no packets.\n' "${0##*/}"
}
die() { printf 'Error: %s\n' "$1" >&2; exit 1; }

ask=1 dry=0 cidr=""
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --yes) ask=0 ;;
    --dry-run) dry=1 ;;
    -*) die "unknown option \"$arg\". Try --help." ;;
    *) cidr=$arg ;;
  esac
done
[[ -n $cidr ]] || { usage >&2; exit 1; }
command -v ping >/dev/null 2>&1 || die 'ping is not installed.'
ip=${cidr%/*}
prefix=${cidr#*/}
[[ $ip != "$cidr" && $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ && $prefix =~ ^[0-9]+$ ]] \
  || die "\"$cidr\" is not an IPv4 CIDR block."
(( prefix >= 24 && prefix <= 30 )) || die 'use a prefix from /24 to /30.'
IFS=. read -r o1 o2 o3 o4 <<< "$ip"
for octet in "$o1" "$o2" "$o3" "$o4"; do
  (( 10#$octet <= 255 )) || die "\"$ip\" has an octet above 255."
done
base=$(( (10#$o1 << 24) + (10#$o2 << 16) + (10#$o3 << 8) + 10#$o4 ))
size=$(( 1 << (32 - prefix) ))
start=$(( (base >> (32 - prefix)) << (32 - prefix) ))
first=$(( start + 1 ))
last=$(( start + size - 2 ))
total=$(( last - first + 1 ))
f=$(( (start >> 24) & 255 ))
s=$(( (start >> 16) & 255 ))
private=0
if (( f == 10 || f == 127 || (f == 172 && s >= 16 && s <= 31) || (f == 192 && s == 168) )); then
  private=1
fi
if (( private == 0 )); then
  printf '⚠️  %s is a public block. Only scan it if you own it.\n' "$cidr" >&2
fi
if (( dry == 1 )); then
  printf '🔎 Dry run: would ping %d addresses in %s.\n' "$total" "$cidr"
  exit 0
fi
if (( ask == 1 )); then
  printf 'Ping %d addresses in %s? [y/N] ' "$total" "$cidr"
  read -r reply || reply=""
  case "$reply" in
    y|Y|yes|YES) ;;
    *) printf 'Cancelled.\n'; exit 1 ;;
  esac
fi
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
if [[ $(uname -s) == Darwin ]]; then wait_flag=1000; else wait_flag=1; fi
running=0
for (( n = first; n <= last; n++ )); do
  addr="$(( (n >> 24) & 255 )).$(( (n >> 16) & 255 )).$(( (n >> 8) & 255 )).$(( n & 255 ))"
  if ping -c 1 -W "$wait_flag" "$addr" >/dev/null 2>&1; then
    printf '%s\n' "$addr" >> "$tmp"
  fi &
  running=$(( running + 1 ))
  if (( running >= 32 )); then wait; running=0; fi
done
wait
count=$(wc -l < "$tmp" | tr -d ' ')
printf '📡 %d of %d addresses replied.\n' "$count" "$total"
if (( count > 0 )); then
  sort -t. -k1,1n -k2,2n -k3,3n -k4,4n "$tmp" | sed 's/^/   ✅ /'
else
  printf '   No replies. Check the route and the firewall.\n'
fi
