#!/usr/bin/env bash
set -euo pipefail

# Send a Wake-on-LAN magic packet to a MAC address.
# Usage: wol.sh [--dry-run] <mac> [broadcast] [port]
# Note: The target must have Wake-on-LAN enabled in its firmware.

usage() {
  printf 'Usage: %s [--dry-run] <mac> [broadcast] [port]\n' "${0##*/}"
  printf '  mac        Address with colons or dashes. Example: aa:bb:cc:dd:ee:ff\n'
  printf '  broadcast  Default: 255.255.255.255\n'
  printf '  port       Default: 9\n'
}

dry=0
args=()
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --dry-run) dry=1 ;;
    -*) printf 'Error: unknown option "%s".\n' "$arg" >&2; exit 1 ;;
    *) args+=("$arg") ;;
  esac
done

if (( ${#args[@]} < 1 )); then
  usage >&2
  exit 1
fi
mac=${args[0]}

raw=$(printf '%s' "$mac" | tr -d ':-')
if [[ ! $raw =~ ^[0-9A-Fa-f]{12}$ ]]; then
  printf 'Error: "%s" is not a MAC address.\n' "$mac" >&2
  exit 1
fi

broadcast=${args[1]:-255.255.255.255}
port=${args[2]:-9}
if [[ ! $broadcast =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
  printf 'Error: "%s" is not an IPv4 broadcast address.\n' "$broadcast" >&2
  exit 1
fi
if [[ ! $port =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
  printf 'Error: "%s" is not a valid port.\n' "$port" >&2
  exit 1
fi

packet='\xff\xff\xff\xff\xff\xff'
i=0
while (( i < 12 )); do
  packet="${packet}\\x${raw:$i:2}"
  i=$(( i + 2 ))
done

full=""
repeats=0
while (( repeats < 16 )); do
  full="${full}${packet}"
  repeats=$(( repeats + 1 ))
done

if (( dry == 1 )); then
  printf '🔎 Dry run: would send a 102-byte magic packet to %s:%s.\n' "$broadcast" "$port"
  exit 0
fi

if ! printf '%b' "$full" > "/dev/udp/$broadcast/$port" 2>/dev/null; then
  printf 'Error: cannot send to %s:%s. Check the broadcast address.\n' "$broadcast" "$port" >&2
  exit 1
fi
printf '⚡ Magic packet sent to %s for %s.\n' "$broadcast" "$mac"
