#!/usr/bin/env bash
set -euo pipefail

# Look up the PTR records for an address or a small block.
# Usage: reverse-dns.sh <ip|cidr>
# Needs: dig

usage() {
  printf 'Usage: %s <ip|cidr>\n  ip     A single IPv4 address. Example: 8.8.8.8\n  cidr   A /24 to /30 block. Only names that exist are listed.\n' "${0##*/}"
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

target=$1
ip=${target%/*}
[[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] \
  || {
    printf 'Error: "%s" is not an IPv4 address.\n' "$target" >&2
    exit 1
  }
IFS=. read -r o1 o2 o3 o4 <<< "$ip"
for octet in "$o1" "$o2" "$o3" "$o4"; do
  ((10#$octet <= 255)) || {
    printf 'Error: "%s" has an octet above 255.\n' "$ip" >&2
    exit 1
  }
done

if [[ $target == "$ip" ]]; then
  name=$(dig +short +time=2 +tries=1 -x "$ip" 2> /dev/null || true)
  if [[ -z $name ]]; then
    printf '🔎 %s has no PTR record.\n' "$ip"
  else
    printf '🔎 %s\n' "$ip"
    printf '%s\n' "$name" | sed 's/^/   → /'
  fi
  exit 0
fi

prefix=${target#*/}
if ! [[ $prefix =~ ^[0-9]+$ ]] || ((prefix < 24 || prefix > 30)); then
  printf 'Error: use a prefix from /24 to /30.\n' >&2
  exit 1
fi

base=$(((10#$o1 << 24) + (10#$o2 << 16) + (10#$o3 << 8) + 10#$o4))
size=$((1 << (32 - prefix)))
start=$(((base >> (32 - prefix)) << (32 - prefix)))
first=$((start + 1))
last=$((start + size - 2))

found=0
for ((n = first; n <= last; n++)); do
  addr="$(((n >> 24) & 255)).$(((n >> 16) & 255)).$(((n >> 8) & 255)).$((n & 255))"
  name=$(dig +short +time=1 +tries=1 -x "$addr" 2> /dev/null || true)
  name=$(printf '%s' "$name" | head -1)
  if [[ -n $name ]]; then
    printf '   %s -> %s\n' "$addr" "$name"
    found=$((found + 1))
  fi
done
printf '📊 %d of %d addresses have a PTR record.\n' "$found" "$((last - first + 1))"
