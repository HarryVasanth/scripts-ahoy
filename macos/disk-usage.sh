#!/usr/bin/env bash
set -euo pipefail

# Shows the biggest items in a folder.
# Usage: disk-usage [DIR] [-n COUNT] [-h]
# Needs: du, sort, awk (POSIX)

show_help() {
  cat << 'EOF'
disk-usage - list the biggest items in a folder.

Usage: disk-usage [DIR] [--count N]

  DIR          Folder to measure. Default: the current folder.
  -n, --count  Number of items to show. Default: 10.
  -h, --help   Show this help.

Only the top level is measured. Use du -sh for a single total.
EOF
}

dir="."
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
    -*)
      printf 'Error: unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
    *)
      dir=$1
      shift
      ;;
  esac
done

if [[ ! $count =~ ^[0-9]+$ ]] || [[ $count -lt 1 ]]; then
  printf 'Error: the count must be a positive number.\n' >&2
  exit 1
fi

if [[ ! -d "$dir" ]]; then
  printf 'Error: the folder does not exist: %s\n' "$dir" >&2
  exit 1
fi

entries=$(du -sk "$dir"/* "$dir"/.[!.]* 2> /dev/null | sort -n | tail -n "$count" || true)

if [[ -z "$entries" ]]; then
  printf '⚠️  Nothing to measure in %s.\n' "$dir"
  exit 0
fi

printf '%8s  %s\n' "SIZE" "PATH"
printf '%s\n' "$entries" | awk '
  {
    kb = $1
    $1 = ""
    sub(/^ /, "")
    if (kb >= 1048576) size = sprintf("%.1fG", kb / 1048576)
    else if (kb >= 1024) size = sprintf("%.1fM", kb / 1024)
    else size = sprintf("%dK", kb)
    printf "%8s  %s\n", size, $0
  }'
