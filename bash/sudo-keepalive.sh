#!/usr/bin/env bash
# Keep the sudo timestamp fresh while a command runs.
# Usage: sudo-keepalive.sh COMMAND [ARGS...]
# Needs: sudo

set -euo pipefail

usage() {
  cat <<'EOF'
Run a command with sudo and keep the rights warm.
Usage: sudo-keepalive.sh COMMAND [ARGS...]

  -h, --help   show this help

The script asks for the sudo password once. A background loop then
refreshes the timestamp every 50 seconds until the command ends.

Example: sudo-keepalive.sh apt-get upgrade
EOF
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

command -v sudo >/dev/null 2>&1 ||
  { printf 'error: sudo is not installed\n' >&2; exit 1; }
(($# > 0)) || { printf 'error: give a command to run with sudo\n' >&2; usage >&2; exit 1; }

printf '🔐 Checking sudo rights...\n' >&2
sudo -v || { printf 'error: sudo did not accept the password\n' >&2; exit 1; }

( while sleep 50; do
    sudo -n true 2>/dev/null || exit
    kill -0 "$$" 2>/dev/null || exit
  done ) &
keeper=$!
trap 'kill "$keeper" 2>/dev/null || true' EXIT INT TERM

printf '🚀 Running: sudo %s\n' "$*" >&2
sudo "$@"
