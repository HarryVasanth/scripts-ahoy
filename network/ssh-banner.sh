#!/usr/bin/env bash
set -euo pipefail

# Read the SSH banner and software version from a host.
# Usage: ssh-banner.sh <host> [port]
# Needs: nc

usage() {
  printf 'Usage: %s <host> [port]\n  port  The default port is 22.\n' "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi
if [[ $# -lt 1 || -z ${1:-} ]]; then
  usage >&2
  exit 1
fi
command -v nc > /dev/null 2>&1 || {
  printf 'Error: nc is not installed.\n' >&2
  exit 1
}

host=$1
port=${2:-22}
[[ $host =~ ^[A-Za-z0-9._:-]+$ ]] \
  || {
    printf 'Error: "%s" is not a valid host.\n' "$host" >&2
    exit 1
  }
[[ $port =~ ^[0-9]+$ ]] \
  || {
    printf 'Error: "%s" is not a valid port.\n' "$port" >&2
    exit 1
  }
((port >= 1 && port <= 65535)) \
  || {
    printf 'Error: "%s" is not a valid port.\n' "$port" >&2
    exit 1
  }

banner=$( (sleep 1) | nc -w 3 "$host" "$port" 2> /dev/null | head -n 1) || banner=""
if [[ -z $banner ]]; then
  printf '❌ No SSH banner from %s:%s. The port may be closed or not SSH.\n' "$host" "$port" >&2
  exit 1
fi

printf '🔐 %s:%s\n' "$host" "$port"
printf '   Banner:  %s\n' "$banner"
version=${banner#SSH-2.0-}
version=${version#SSH-1.99-}
if [[ $version != "$banner" ]]; then
  printf '   Software: %s\n' "$version"
else
  printf '   ⚠️  The banner is not in the SSH-2.0 format.\n'
fi
