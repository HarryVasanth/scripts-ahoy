#!/usr/bin/env bash
# Check a host for weak TLS protocols and ciphers.
# Usage: openssl-audit.sh [-p PORT] HOST
# Needs: openssl
# Note: This opens several connections. Use it only on hosts you own.

set -euo pipefail

PORT=443
HOST=
WEAK=0

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -p) [ "$#" -ge 2 ] || die "-p needs a port."; PORT=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option $1" ;;
    *) [ -z "$HOST" ] || die "give one host name only."; HOST=$1; shift ;;
  esac
done

[ -n "$HOST" ] || die "give a host name. See --help."
case "$PORT" in
  ''|*[!0-9]*) die "-p needs a number." ;;
esac
command -v openssl >/dev/null 2>&1 || die "openssl is not installed."

probe() {
  local pid watcher rc=0
  (printf '' | openssl s_client -connect "$HOST:$PORT" "$@" >/dev/null 2>&1) &
  pid=$!
  (sleep 10; kill "$pid" 2>/dev/null) >/dev/null 2>&1 &
  watcher=$!
  wait "$pid" || rc=$?
  kill "$watcher" 2>/dev/null || true
  return "$rc"
}

try() {
  local label=$1 mode=$2
  shift 2
  if probe "$@"; then
    if [ "$mode" = weak ]; then
      printf '⚠️  %-8s supported or accepted (weak)\n' "$label"
      WEAK=$((WEAK + 1))
    else
      printf '✅ %-8s supported\n' "$label"
    fi
  elif [ "$mode" = good ]; then
    printf '❌ %-8s not supported. Most clients now need it.\n' "$label"
  else
    printf '✅ %-8s not supported\n' "$label"
  fi
}

printf '🔎 TLS check for %s:%s\n\n' "$HOST" "$PORT"
try 'TLS 1.2' good -tls1_2
try 'SSL 3.0' weak -ssl3
try 'TLS 1.0' weak -tls1
try 'TLS 1.1' weak -tls1_1

printf '\n🔎 Weak cipher groups\n\n'
try 'RC4' weak -cipher RC4
try '3DES' weak -cipher 3DES
try 'NULL' weak -cipher NULL

if [ "$WEAK" -eq 0 ]; then
  printf '\n✅ No weak protocol or cipher was accepted.\n'
else
  printf '\n⚠️  %s weak option(s) accepted. Turn them off in the server config.\n' "$WEAK"
fi
