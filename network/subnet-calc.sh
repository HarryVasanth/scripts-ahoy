#!/usr/bin/env bash
set -euo pipefail

# Calculate the addresses of an IPv4 subnet.
# Usage: subnet-calc.sh <cidr>

usage() {
  printf 'Usage: %s <cidr>\n' "${0##*/}"
  printf 'Example: %s 192.168.1.10/24\n' "${0##*/}"
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi
if [[ $# -lt 1 || -z ${1:-} ]]; then
  usage >&2
  exit 1
fi

cidr=$1
ip=${cidr%/*}
prefix=${cidr#*/}
if [[ $ip == "$cidr" || ! $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || ! $prefix =~ ^[0-9]+$ ]]; then
  printf 'Error: "%s" is not an IPv4 CIDR block.\n' "$cidr" >&2
  exit 1
fi
if (( prefix > 32 )); then
  printf 'Error: the prefix must be from 0 to 32.\n' >&2
  exit 1
fi

IFS=. read -r o1 o2 o3 o4 <<< "$ip"
for octet in "$o1" "$o2" "$o3" "$o4"; do
  if (( 10#$octet > 255 )); then
    printf 'Error: "%s" has an octet above 255.\n' "$ip" >&2
    exit 1
  fi
done

int_to_ip() {
  printf '%s.%s.%s.%s' \
    "$(( ($1 >> 24) & 255 ))" "$(( ($1 >> 16) & 255 ))" \
    "$(( ($1 >> 8) & 255 ))" "$(( $1 & 255 ))"
}

base=$(( (10#$o1 << 24) + (10#$o2 << 16) + (10#$o3 << 8) + 10#$o4 ))
mask=$(( (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF ))
network=$(( base & mask ))
broadcast=$(( network | (~mask & 0xFFFFFFFF) ))
size=$(( 1 << (32 - prefix) ))

if (( prefix == 32 )); then
  first=$network
  last=$network
  hosts=1
elif (( prefix == 31 )); then
  first=$network
  last=$broadcast
  hosts=2
else
  first=$(( network + 1 ))
  last=$(( broadcast - 1 ))
  hosts=$(( size - 2 ))
fi

printf '🌐 %s\n' "$cidr"
printf '   Network:    %s\n' "$(int_to_ip "$network")"
printf '   Netmask:    %s\n' "$(int_to_ip "$mask")"
printf '   Broadcast:  %s\n' "$(int_to_ip "$broadcast")"
printf '   First host: %s\n' "$(int_to_ip "$first")"
printf '   Last host:  %s\n' "$(int_to_ip "$last")"
printf '   Hosts:      %d\n' "$hosts"
