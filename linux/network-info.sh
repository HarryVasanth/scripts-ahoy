#!/usr/bin/env bash
set -euo pipefail

# Shows interfaces, addresses, routes and DNS servers.
# Usage: network-info [INTERFACE] [-h]
# Needs: ip or ifconfig

show_help() {
  cat << 'EOF'
network-info - show the local network configuration.

Usage: network-info [INTERFACE]

  INTERFACE   Show one interface only. Example: en0 or eth0.
  -h, --help  Show this help.

The tool uses ip on Linux and ifconfig on macOS.
EOF
}

iface=""
for arg in "$@"; do
  case "$arg" in
    -h | --help)
      show_help
      exit 0
      ;;
    -*)
      printf 'Error: unknown argument: %s\n' "$arg" >&2
      exit 1
      ;;
    *)
      [[ -z "$iface" ]] || {
        printf 'Error: give one interface only.\n' >&2
        exit 1
      }
      iface=$arg
      ;;
  esac
done

if command -v ip > /dev/null 2>&1; then
  if [[ -n "$iface" ]]; then
    printf '== %s ==\n' "$iface"
    ip -brief addr show "$iface"
    printf '\nRoute:\n'
    ip route show default
  else
    printf '== Interfaces ==\n'
    ip -brief addr
    printf '\n== Routes ==\n'
    ip route
  fi
else
  if [[ -n "$iface" ]]; then
    printf '== %s ==\n' "$iface"
    ifconfig "$iface"
    printf '\nRoute:\n'
  else
    printf '== Interfaces ==\n'
    ifconfig -a
    printf '\n== Routes ==\n'
  fi
  netstat -rn -f inet 2> /dev/null | head -n 15
fi

printf '\n== DNS servers ==\n'
if command -v scutil > /dev/null 2>&1; then
  scutil --dns 2> /dev/null | awk '/nameserver\[/ {print "  " $3}' | sort -u
else
  awk '/^nameserver/ {print "  " $2}' /etc/resolv.conf 2> /dev/null || printf '  Unknown.\n'
fi
