#!/usr/bin/env bash
# Remove ANSI colour codes from text.
# Usage: strip-ansi.sh [FILE...]
# Note: reads standard input when no FILE is given.

set -euo pipefail

usage() {
  cat << 'EOF'
Strip terminal escape sequences from text.
Usage: strip-ansi.sh [FILE...]

  -h, --help  show this help

Reads standard input when no FILE is given.
EOF
}

files=()
while (($# > 0)); do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -) files+=("/dev/stdin") ;;
    -*)
      printf 'error: unknown option %s\n' "$1" >&2
      exit 1
      ;;
    *) files+=("$1") ;;
  esac
  shift
done

if ((${#files[@]} > 0)); then
  for f in "${files[@]}"; do
    [[ -r "$f" ]] || {
      printf 'error: cannot read %s\n' "$f" >&2
      exit 1
    }
  done
fi

strip() {
  awk '
    BEGIN { esc = sprintf("%c", 27) }
    {
      line = $0
      gsub(esc "\\[[0-9;?]*[A-Za-z]", "", line)
      gsub(esc "\\][^\a]*\a", "", line)
      sub(/\r$/, "", line)
      print line
    }
  '
}

if ((${#files[@]} == 0)); then
  strip
else
  for f in "${files[@]}"; do
    strip < "$f"
  done
fi
