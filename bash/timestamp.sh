#!/usr/bin/env bash
# Show the current time, or convert an epoch, in a useful format.
# Usage: timestamp.sh [--epoch|--iso|--file] [--utc] [EPOCH]
# Note: --file gives a name-safe stamp like 2026-11-19_14-05-09.

set -euo pipefail

mode="iso"
utc=0
epoch=""

usage() {
  cat << 'EOF'
Show the current time in a chosen format.
Usage: timestamp.sh [--epoch|--iso|--file] [--utc] [EPOCH]

  --epoch    seconds since the Unix epoch
  --iso      ISO 8601 stamp (default)
  --file     name-safe stamp, for example 2026-11-19_14-05-09
  --utc      use UTC instead of local time
  -h, --help show this help

Pass EPOCH to convert a known time instead of now.
EOF
}

while (($# > 0)); do
  case "$1" in
    --epoch) mode="epoch" ;;
    --iso) mode="iso" ;;
    --file) mode="file" ;;
    --utc) utc=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      printf 'error: unknown option %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -n "$epoch" ]]; then
        printf 'error: give one epoch only\n' >&2
        exit 1
      fi
      epoch="$1"
      ;;
  esac
  shift
done

if [[ -z "$epoch" ]]; then
  epoch=$(date +%s)
elif [[ ! "$epoch" =~ ^[0-9]+$ ]]; then
  printf 'error: EPOCH must be a whole number of seconds\n' >&2
  exit 1
fi

if [[ "$mode" == "epoch" ]]; then
  printf '%s\n' "$epoch"
  exit 0
fi

if ((utc)); then
  export TZ=UTC
fi

fmt='+%Y-%m-%dT%H:%M:%S%z'
if [[ "$mode" == "file" ]]; then
  fmt='+%Y-%m-%d_%H-%M-%S'
fi

# BSD date reads epochs with -r, GNU date with -d @.
if date -r 0 +%s > /dev/null 2>&1; then
  date -r "$epoch" "$fmt"
else
  date -d "@$epoch" "$fmt"
fi
