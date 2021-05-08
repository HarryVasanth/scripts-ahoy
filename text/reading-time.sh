#!/usr/bin/env bash
# Estimate how long a text takes to read.
# Usage: reading-time.sh [-w WPM] [FILE...]

set -euo pipefail

wpm=200

usage() {
  cat <<'EOF'
Show the reading time of one or more text files.
Usage: reading-time.sh [-w WPM] [FILE...]

  -w WPM      reading speed in words per minute (default: 200)
  -h, --help  show this help

Reads standard input when no FILE is given.
EOF
}

while (($# > 0)); do
  case "$1" in
    -w|--wpm)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      wpm="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
  shift
done

[[ "$wpm" =~ ^[1-9][0-9]*$ ]] || { printf 'error: WPM must be a positive number\n' >&2; exit 1; }
for f in "$@"; do
  [[ -r "$f" ]] || { printf 'error: cannot read %s\n' "$f" >&2; exit 1; }
done

report() {
  local label="$1" count="$2" minutes
  minutes=$(( (count + wpm - 1) / wpm ))
  if ((minutes < 1)); then
    minutes=1
  fi
  printf '📖 %s: %d min (%d words)\n' "$label" "$minutes" "$count"
}

if (($# == 0)); then
  report "stdin" "$(wc -w | tr -d ' ')"
else
  for f in "$@"; do
    report "$f" "$(wc -w < "$f" | tr -d ' ')"
  done
fi
