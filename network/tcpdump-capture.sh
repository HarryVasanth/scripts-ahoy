#!/usr/bin/env bash
set -euo pipefail

# Capture network traffic to a pcap file with a filter.
# Usage: tcpdump-capture.sh [-i <interface>] [-c <count>] <filter...>
# Needs: tcpdump
# Note: This needs root. It writes a pcap file and changes nothing else.

usage() {
  printf 'Usage: %s [-i <interface>] [-c <count>] <filter...>\n' "${0##*/}"
  printf '  -i  Interface. Default: the default route interface.\n'
  printf '  -c  Packet count. Default: 200\n'
  printf 'Example: sudo %s -i en0 -c 100 tcp port 443\n' "${0##*/}"
}

iface=""
count=200
while (( $# > 0 )); do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -i)
      [[ $# -ge 2 ]] || { printf 'Error: -i needs a value.\n' >&2; exit 1; }
      iface=$2
      shift 2
      ;;
    -c)
      [[ $# -ge 2 ]] || { printf 'Error: -c needs a value.\n' >&2; exit 1; }
      count=$2
      shift 2
      ;;
    *) break ;;
  esac
done

(( EUID == 0 )) || { printf 'Error: run this script as root. Try: sudo %s ...\n' "${0##*/}" >&2; exit 1; }
command -v tcpdump >/dev/null 2>&1 || { printf 'Error: tcpdump is not installed.\n' >&2; exit 1; }
[[ $count =~ ^[1-9][0-9]*$ ]] || { printf 'Error: count must be a positive number.\n' >&2; exit 1; }
if (( $# == 0 )); then
  printf 'Error: give a capture filter, for example: tcp port 443\n' >&2
  exit 1
fi
if [[ -z $iface ]]; then
  if [[ $(uname -s) == Darwin ]]; then
    iface=$(route -n get default 2>/dev/null | awk '/interface:/ { print $2; exit }') || iface=""
  else
    iface=$(ip route show default 2>/dev/null | awk '{ print $5; exit }') || iface=""
  fi
  [[ -n $iface ]] || { printf 'Error: cannot find the default interface. Use -i.\n' >&2; exit 1; }
fi

out="tcpdump-$(date +%Y%m%d-%H%M%S).pcap"
printf '📦 Capturing %s packets on %s to %s\n' "$count" "$iface" "$out" >&2
printf '   Press Ctrl-C to stop early.\n' >&2
tcpdump -i "$iface" -c "$count" -w "$out" "$@" || true
printf '✅ Saved %s\n' "$out"
