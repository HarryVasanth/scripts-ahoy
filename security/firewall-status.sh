#!/usr/bin/env bash
# Show the state of the local firewall.
# Usage: firewall-status.sh [-h]
# Note: Some checks need sudo to read the rules.

set -euo pipefail

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    *) die "unknown option $1" ;;
  esac
done

if [ "$(uname -s)" = Darwin ]; then
  printf '🔎 macOS application firewall\n'
  /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2> /dev/null \
    || printf '   State not available.\n'
  /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2> /dev/null || true
  printf '\n🔎 Packet filter\n   Run for details: sudo pfctl -s info\n'
  exit 0
fi

FOUND=0
if command -v ufw > /dev/null 2>&1; then
  FOUND=1
  printf '🔎 ufw\n'
  sudo -n ufw status 2> /dev/null || printf '   Needs root. Run: sudo ufw status\n'
fi
if command -v firewall-cmd > /dev/null 2>&1; then
  FOUND=1
  printf '\n🔎 firewalld\n'
  firewall-cmd --state 2> /dev/null || printf '   Needs root, or the service is off.\n'
  firewall-cmd --list-all 2> /dev/null || printf '   Run for details: sudo firewall-cmd --list-all\n'
fi
if command -v nft > /dev/null 2>&1; then
  FOUND=1
  printf '\n🔎 nftables\n'
  sudo -n nft list ruleset 2> /dev/null || printf '   Needs root. Run: sudo nft list ruleset\n'
fi
if [ "$FOUND" -eq 0 ] && command -v iptables > /dev/null 2>&1; then
  FOUND=1
  printf '🔎 iptables\n'
  sudo -n iptables -S 2> /dev/null || printf '   Needs root. Run: sudo iptables -S\n'
fi
if [ "$FOUND" -eq 0 ]; then
  printf '⚠️  No firewall tool found.\n'
fi
