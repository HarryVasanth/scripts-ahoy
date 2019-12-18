#!/usr/bin/env bash
# Find the process that listens on a TCP port and stop it.
# Usage: port-kill [--dry-run] [--force] <port>
# Needs: lsof (or ss on Linux)
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: port-kill [--dry-run] [--force] <port>

Show the processes that listen on the port, then ask before stopping them.

  --dry-run   Show the processes. Stop nothing.
  --force     Send SIGKILL when SIGTERM is not enough.
  -h, --help  Show this help.
EOF
}

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

dry_run=0
force=0
port=""
while (($# > 0)); do
  case "$1" in
    --dry-run) dry_run=1 ;;
    --force) force=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "Unknown option: $1" ;;
    *) [[ -z "$port" ]] || die 'Pass one port only.'; port="$1" ;;
  esac
  shift
done

[[ "$port" =~ ^[0-9]+$ ]] || die 'The port must be a number.'
port=$((10#$port))
((port >= 1 && port <= 65535)) || die 'The port must be between 1 and 65535.'

if command -v lsof >/dev/null 2>&1; then
  raw=$(lsof -nP -iTCP:"$port" -sTCP:LISTEN -t 2>/dev/null || true)
elif command -v ss >/dev/null 2>&1; then
  raw=$(ss -ltnp 2>/dev/null | awk -v want=":$port" '$4 ~ want "$" { print $NF }' |
    sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p' | sort -u)
else
  die 'lsof is not installed. Install it, or check the port with: ss -ltnp'
fi

[[ -n "$raw" ]] || { printf 'ℹ️  Nothing is listening on port %s.\n' "$port"; exit 0; }
pids=()
while IFS= read -r pid; do
  [[ -z "$pid" ]] || pids+=("$pid")
done <<< "$raw"

printf '🔎 Port %s is used by:\n' "$port" >&2
for pid in "${pids[@]}"; do
  printf '   PID %s  %s\n' "$pid" "$(ps -p "$pid" -o comm= 2>/dev/null || printf 'unknown')"
done
((dry_run == 0)) || { printf '🔍 Dry run. Nothing was stopped.\n' >&2; exit 0; }

read -r -p 'Stop these processes? [y/N] ' reply
[[ "$reply" =~ ^[Yy]$ ]] || { printf '👋 Nothing was stopped.\n' >&2; exit 0; }

for pid in "${pids[@]}"; do
  kill -TERM "$pid" 2>/dev/null || printf '⚠️  PID %s is already gone.\n' "$pid" >&2
done
sleep 2

remaining=()
for pid in "${pids[@]}"; do
  if kill -0 "$pid" 2>/dev/null; then remaining+=("$pid"); fi
done
if ((${#remaining[@]} > 0)); then
  ((force == 1)) || die "Still running: ${remaining[*]}. Use --force to send SIGKILL."
  for pid in "${remaining[@]}"; do
    kill -9 "$pid" 2>/dev/null || true
    printf '💀 Sent SIGKILL to %s\n' "$pid" >&2
  done
fi

printf '✅ Port %s is free.\n' "$port"
