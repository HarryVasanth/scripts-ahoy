#!/usr/bin/env bash
set -euo pipefail

# Shows recent error-level entries from the systemd journal.
# Usage: journal-errors [-s|--since TIME] [-n LINES] [-u|--unit UNIT] [-h]
# Needs: journalctl (systemd)

show_help() {
  cat << 'EOF'
journal-errors - show recent journal errors.

Usage: journal-errors [options]

  -s, --since TIME   Start time. Default: "1 hour ago".
  -n, --lines N      Maximum number of lines. Default: 50.
  -u, --unit UNIT    Only show one unit.
  -h, --help         Show this help.

Examples:
  journal-errors --since today --lines 100
  journal-errors --unit nginx --since "30 min ago"
EOF
}

since="1 hour ago"
lines=50
unit=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s | --since)
      [[ $# -ge 2 ]] || {
        printf 'Error: %s needs a value.\n' "$1" >&2
        exit 1
      }
      since=$2
      shift 2
      ;;
    -n | --lines)
      [[ $# -ge 2 ]] || {
        printf 'Error: %s needs a value.\n' "$1" >&2
        exit 1
      }
      lines=$2
      shift 2
      ;;
    -u | --unit)
      [[ $# -ge 2 ]] || {
        printf 'Error: %s needs a value.\n' "$1" >&2
        exit 1
      }
      unit=$2
      shift 2
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      printf 'Error: unknown argument: %s\n' "$1" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

if [[ ! $lines =~ ^[0-9]+$ ]] || [[ $lines -lt 1 ]]; then
  printf 'Error: the line count must be a positive number.\n' >&2
  exit 1
fi

if ! command -v journalctl > /dev/null 2>&1; then
  printf 'Error: journalctl is missing. This tool needs systemd.\n' >&2
  exit 1
fi

args=(-p err --since "$since" -n "$lines" --no-pager -o short-iso)
if [[ -n "$unit" ]]; then
  args+=(-u "$unit")
fi

output=$(journalctl "${args[@]}" 2> /dev/null || true)

if [[ -z "$output" || "$output" == *"No entries"* ]]; then
  printf '✅ No errors since %s.\n' "$since"
  exit 0
fi

printf '%s\n' "$output"
