#!/usr/bin/env bash
# Add or subtract days from a date.
# Usage: date-math.sh [-b YYYY-MM-DD] OFFSET

set -euo pipefail

base=$(date '+%Y-%m-%d')

usage() {
  cat << 'EOF'
Move a date forward or back.
Usage: date-math.sh [-b YYYY-MM-DD] OFFSET

  -b, --base DATE   start date (default: today)
  -h, --help        show this help

OFFSET is a number of days, with an optional sign.
Example: date-math.sh -b 2024-02-28 +2
Example: date-math.sh -7
EOF
}

while (($# > 0)); do
  case "$1" in
    -b | --base)
      (($# >= 2)) || {
        printf 'error: %s needs a date\n' "$1" >&2
        exit 1
      }
      base="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -[0-9]*) break ;;
    -*)
      printf 'error: unknown option %s\n' "$1" >&2
      exit 1
      ;;
    *) break ;;
  esac
done

(($# == 1)) || {
  printf 'error: give one day offset\n' >&2
  usage >&2
  exit 1
}
offset="$1"

[[ "$offset" =~ ^[-+]?[0-9]+$ ]] \
  || {
    printf 'error: OFFSET must be a whole number of days\n' >&2
    exit 1
  }
[[ "$base" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] \
  || {
    printf 'error: BASE must look like YYYY-MM-DD\n' >&2
    exit 1
  }

if date -d "@0" '+%Y' > /dev/null 2>&1; then
  result=$(date -d "$base $offset days" '+%Y-%m-%d') \
    || {
      printf 'error: cannot work out the date from %s\n' "$base" >&2
      exit 1
    }
else
  if [[ "$offset" == -* ]]; then
    sign="-"
  else
    sign="+"
  fi
  days=${offset#[-+]}
  result=$(date -j -v"${sign}${days}d" -f '%Y-%m-%d' "$base" '+%Y-%m-%d') \
    || {
      printf 'error: cannot work out the date from %s\n' "$base" >&2
      exit 1
    }
fi

printf '🗓️  %s\n' "$result"
