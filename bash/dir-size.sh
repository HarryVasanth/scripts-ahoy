#!/usr/bin/env bash
# Show the size of each entry in a directory, largest first.
# Usage: dir-size.sh [-n COUNT] [DIR]

set -euo pipefail

count=15
dir="."

usage() {
  cat << 'EOF'
List directory entries by size, largest first.
Usage: dir-size.sh [-n COUNT] [DIR]

  -n COUNT    show this many entries (default: 15, 0 for all)
  -h, --help  show this help

The total for all entries is printed last.
EOF
}

while (($# > 0)); do
  case "$1" in
    -n | --count)
      (($# >= 2)) || {
        printf 'error: %s needs a value\n' "$1" >&2
        exit 1
      }
      count="$2"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      printf 'error: unknown option %s\n' "$1" >&2
      exit 1
      ;;
    *) break ;;
  esac
  shift
done

(($# <= 1)) || {
  printf 'error: give one directory only\n' >&2
  exit 1
}
[[ "$count" =~ ^[0-9]+$ ]] || {
  printf 'error: COUNT must be a whole number\n' >&2
  exit 1
}
if (($# == 1)); then
  dir="$1"
fi
[[ -d "$dir" ]] || {
  printf 'error: %s is not a directory\n' "$dir" >&2
  exit 1
}

printf '📊 Sizes inside %s\n' "$dir" >&2

rows=$(find "$dir" -mindepth 1 -maxdepth 1 -exec du -sk {} + | sort -rn)
if ((count > 0)); then
  rows=$(printf '%s\n' "$rows" | head -n "$count")
fi

printf '%s\n' "$rows" | awk 'NF >= 2 {
  kb = $1
  $1 = ""
  sub(/^ +/, "")
  if (kb >= 1048576) printf "%8.2f GB  %s\n", kb / 1048576, $0
  else if (kb >= 1024) printf "%8.1f MB  %s\n", kb / 1024, $0
  else printf "%8d KB  %s\n", kb, $0
}'

total=$(du -sk "$dir" | awk '{ print $1 }')
printf '   ------\n%8.1f MB  total\n' "$(awk -v k="$total" 'BEGIN { print k / 1024 }')"
