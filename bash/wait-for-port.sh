#!/usr/bin/env bash
# Wait until a TCP port accepts connections.
# Usage: wait-for-port.sh [-t TIMEOUT] [-i INTERVAL] [-q] HOST PORT

set -euo pipefail

timeout=30
interval=1
quiet=0

usage() {
  cat <<'EOF'
Wait for a TCP port to open, then exit 0.
Usage: wait-for-port.sh [-t TIMEOUT] [-i INTERVAL] [-q] HOST PORT

  -t TIMEOUT     give up after this many seconds (default: 30)
  -i INTERVAL    seconds between checks (default: 1)
  -q, --quiet    hide the waiting message
  -h, --help     show this help
EOF
}

while (($# > 0)); do
  case "$1" in
    -t|--timeout)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      timeout="$2"; shift 2 ;;
    -i|--interval)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      interval="$2"; shift 2 ;;
    -q|--quiet) quiet=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
done

(($# == 2)) || { printf 'error: give HOST and PORT\n' >&2; usage >&2; exit 1; }
host="$1"
port="$2"
if ! [[ "$port" =~ ^[0-9]+$ ]] || ((port < 1 || port > 65535)); then
  printf 'error: PORT must be a number from 1 to 65535\n' >&2
  exit 1
fi
[[ "$interval" =~ ^[1-9][0-9]*$ ]] || { printf 'error: INTERVAL must be a positive number\n' >&2; exit 1; }
[[ "$timeout" =~ ^[0-9]+$ ]] || { printf 'error: TIMEOUT must be a number\n' >&2; exit 1; }

((quiet)) || printf '⏳ Waiting for %s:%s ...\n' "$host" "$port" >&2

start=$(date +%s)
while :; do
  if (exec 3<>"/dev/tcp/$host/$port") 2>/dev/null; then
    printf '✅ %s:%s is open\n' "$host" "$port" >&2
    exit 0
  fi

  now=$(date +%s)
  if ((now - start >= timeout)); then
    printf '❌ Timed out after %d second(s) waiting for %s:%s\n' "$timeout" "$host" "$port" >&2
    exit 1
  fi
  sleep "$interval"
done
