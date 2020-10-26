#!/usr/bin/env bash
set -euo pipefail

# Tests the logrotate configuration in debug mode.
# Usage: logrotate-check [CONFIG] [-h]
# Needs: logrotate

if [[ $(uname -s) != Linux ]]; then
  printf 'Error: this tool needs Linux.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
logrotate-check - test the logrotate configuration.

Usage: logrotate-check [CONFIG]

The tool runs "logrotate -d" on /etc/logrotate.conf, or on the file that you
give. A debug run does not rotate any log. Some files need sudo to read.
EOF
}

config=/etc/logrotate.conf
case $# in
  0) ;;
  1)
    if [[ $1 == -h || $1 == --help ]]; then
      show_help
      exit 0
    fi
    config=$1
    ;;
  *)
    printf 'Error: give one configuration file at most.\n' >&2
    exit 1
    ;;
esac

if ! command -v logrotate >/dev/null 2>&1; then
  printf 'Error: logrotate is not installed.\n' >&2
  printf 'Install it: sudo apt install logrotate  (or: sudo dnf install logrotate)\n' >&2
  exit 1
fi

if [[ ! -r "$config" ]]; then
  printf 'Error: cannot read %s. Try: sudo %s\n' "$config" "$0" >&2
  exit 1
fi

tmp=$(mktemp) || exit 1
trap 'rm -f "$tmp"' EXIT

status=0
logrotate -d "$config" >"$tmp" 2>&1 || status=$?
errors=$(grep -ci 'error' "$tmp" || true)
logs=$(grep -c '^considering log' "$tmp" || true)

if [[ $status -ne 0 || $errors -gt 0 ]]; then
  printf '❌ logrotate found problems in %s\n' "$config"
  grep -i 'error' "$tmp" | head -n 15 >&2 || true
  exit 1
fi

printf '✅ %s is valid. %s log entries were considered.\n' "$config" "$logs"
if [[ $logs -eq 0 ]]; then
  printf '⚠️  No logs matched. Check the include paths in the configuration.\n'
fi
