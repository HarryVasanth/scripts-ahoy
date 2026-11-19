#!/usr/bin/env bash
# List the largest files under a directory.
# Usage: find-large-files.sh [-n COUNT] [-d DIR] SIZE
# Note: SIZE uses find units, for example 100M or 1G.

set -euo pipefail

count=20
dir="."

usage() {
  cat << 'EOF'
Find files above a size and sort them by size.
Usage: find-large-files.sh [-n COUNT] [-d DIR] SIZE

  -n COUNT    show this many files (default: 20)
  -d DIR      search this directory (default: current directory)
  -h, --help  show this help

SIZE is a number with an optional unit: k, M or G.
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
      shift 2
      ;;
    -d | --dir)
      (($# >= 2)) || {
        printf 'error: %s needs a value\n' "$1" >&2
        exit 1
      }
      dir="$2"
      shift 2
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
done

(($# == 1)) || {
  printf 'error: give one SIZE\n' >&2
  usage >&2
  exit 1
}
[[ "$count" =~ ^[1-9][0-9]*$ ]] || {
  printf 'error: COUNT must be a positive number\n' >&2
  exit 1
}
[[ -d "$dir" ]] || {
  printf 'error: %s is not a directory\n' "$dir" >&2
  exit 1
}

size="$1"
[[ "$size" =~ ^[0-9]+[kKmMgG]$ ]] || {
  printf 'error: SIZE needs a unit. Use a number, then k, M or G.\n' >&2
  exit 1
}

amount="${size%[kKmMgG]}"
suffix=""
case "$size" in
  *k | *K) suffix="k" ;;
  *m | *M) suffix="M" ;;
  *g | *G) suffix="G" ;;
esac

printf '🔎 Searching %s for files over %s%s ...\n' "$dir" "$amount" "$suffix" >&2

find "$dir" -type f -size +"$amount$suffix" -exec du -k {} + \
  | sort -rn \
  | head -n "$count" \
  | awk '{ kb = $1; $1 = ""; sub(/^ /, ""); printf "%9.1f MB  %s\n", kb / 1024, $0 }'
