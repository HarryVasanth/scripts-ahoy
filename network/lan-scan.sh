#!/usr/bin/env bash
set -euo pipefail
# Find devices on the local network and show their MAC addresses.
# Usage: lan-scan.sh [--yes] [--dry-run] [cidr]
# Needs: ping, arp
# Note: Scan only networks that you own or have permission to test.

usage() {
  printf 'Usage: %s [--yes] [--dry-run] [cidr]\n  cidr       A /24 block. Default: your local /24\n  --yes      Do not ask for confirmation.\n  --dry-run  Show the plan. Send no packets.\n' "${0##*/}"
}
die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}
ask=1 dry=0 args=()
for arg in "$@"; do
  case "$arg" in
    -h | --help)
      usage
      exit 0
      ;;
    --yes) ask=0 ;;
    --dry-run) dry=1 ;;
    -*) die "unknown option \"$arg\". Try --help." ;;
    *) args+=("$arg") ;;
  esac
done
if ! command -v ping > /dev/null 2>&1 || ! command -v arp > /dev/null 2>&1; then
  die 'ping and arp are required.'
fi

if ((${#args[@]} == 0)); then
  if command -v ifconfig > /dev/null 2>&1; then
    local_ip=$(ifconfig 2> /dev/null | awk '/inet / && $2 !~ /^127\./ { print $2; exit }')
  else
    local_ip=$(ip -4 -o addr show scope global 2> /dev/null | awk '{ print $4; exit }' | cut -d/ -f1)
  fi
  [[ -n ${local_ip:-} ]] || die 'cannot find a local IPv4 address. Pass a CIDR block.'
  args=("${local_ip%.*}.0/24")
fi
cidr=${args[0]}
ip=${cidr%/*}
prefix=${cidr#*/}
if [[ $ip == "$cidr" || ! $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ || $prefix != 24 ]]; then
  die "\"$cidr\" is not a /24 block."
fi
IFS=. read -r o1 o2 o3 o4 <<< "$ip"
for octet in "$o1" "$o2" "$o3" "$o4"; do ((10#$octet <= 255)) || die "\"$ip\" has an octet above 255."; done
range="${ip%.*}."
f=$((10#$o1))
s=$((10#$o2))
if ((f != 10 && f != 127 && !(f == 172 && s >= 16 && s <= 31) && !(f == 192 && s == 168))); then
  printf '⚠️  %s is a public block. Only scan it if you own it.\n' "$cidr" >&2
fi
if ((dry == 1)); then
  printf '🔎 Dry run: would ping 254 addresses in %s.\n' "$cidr"
  exit 0
fi
if ((ask == 1)); then
  printf 'Ping 254 addresses in %s? [y/N] ' "$cidr"
  read -r reply || reply=""
  case "$reply" in
    y | Y | yes | YES) ;;
    *)
      printf 'Cancelled.\n'
      exit 1
      ;;
  esac
fi
if [[ $(uname -s) == Darwin ]]; then wait_flag=1000; else wait_flag=1; fi
running=0
for ((n = 1; n <= 254; n++)); do
  ping -c 1 -W "$wait_flag" "$range$n" > /dev/null 2>&1 &
  running=$((running + 1))
  if ((running >= 32)); then
    wait
    running=0
  fi
done
wait
devices=$(arp -an | awk -v p="$range" -F'[()]' '
  index($2, p) == 1 && $3 ~ / at / {
    mac = $3; sub(/^ at /, "", mac); sub(/ .*/, "", mac)
    if (mac ~ /^([0-9a-fA-F][0-9a-fA-F]:){5}[0-9a-fA-F][0-9a-fA-F]$/) print $2, mac
  }' | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n)
printf '📡 Devices in %s\n' "$cidr"
if [[ -z $devices ]]; then
  printf '   No devices found. Some hosts may block ping.\n'
else
  printf '%s\n' "$devices" | sed 's/^/   /'
  printf '📊 %d devices found.\n' "$(printf '%s\n' "$devices" | wc -l | tr -d ' ')"
fi
