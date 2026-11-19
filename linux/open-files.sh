#!/usr/bin/env bash
set -euo pipefail

# Shows the processes with the most open files.
# Usage: open-files [-n COUNT] [-h]
# Needs: Linux /proc

if [[ ! -d /proc/1/fd ]]; then
  printf 'Error: /proc is missing. This tool needs Linux.\n' >&2
  exit 1
fi

show_help() {
  cat << 'EOF'
open-files - show the processes with the most open files.

Usage: open-files [-n COUNT]

  -n, --count COUNT   Number of processes to show. Default: 10.
  -h, --help          Show this help.

The tool counts the entries in /proc/PID/fd. Without sudo it sees only your
own processes.
EOF
}

count=10
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n | --count)
      [[ $# -ge 2 ]] || {
        printf 'Error: %s needs a value.\n' "$1" >&2
        exit 1
      }
      count=$2
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

if [[ ! $count =~ ^[0-9]+$ ]] || [[ $count -eq 0 ]]; then
  printf 'Error: the count must be a positive number.\n' >&2
  exit 1
fi

if [[ $(id -u) -ne 0 ]]; then
  printf 'Note: you are not root, so counts cover your own processes only.\n' >&2
  printf '      Use sudo to count files for all users.\n' >&2
fi

tmp=$(mktemp) || exit 1
trap 'rm -f "$tmp"' EXIT
find /proc/[0-9]*/fd -mindepth 1 -maxdepth 1 2> /dev/null > "$tmp" || true

printf '📂 Top %s processes by open file count\n' "$count"
printf '%6s  %-20s %s\n' 'FILES' 'PROCESS' 'PID'
awk -F/ '{print $3}' "$tmp" \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -n "$count" \
  | while read -r files pid; do
    name=$(cat "/proc/$pid/comm" 2> /dev/null || printf 'unknown')
    printf '%6s  %-20s %s\n' "$files" "$name" "$pid"
  done
