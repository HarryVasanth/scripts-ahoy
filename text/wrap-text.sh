#!/usr/bin/env bash
# Wrap long lines to a chosen width.
# Usage: wrap-text.sh [-w WIDTH] [FILE...]

set -euo pipefail

width=80

usage() {
  cat << 'EOF'
Wrap text at spaces near the chosen width.
Usage: wrap-text.sh [-w WIDTH] [FILE...]

  -w, --width WIDTH   line width (default: 80)
  -h, --help          show this help

Reads standard input when no FILE is given.
A word longer than WIDTH is left on its own line.
EOF
}

while (($# > 0)); do
  case "$1" in
    -w | --width)
      (($# >= 2)) || {
        printf 'error: %s needs a width\n' "$1" >&2
        exit 1
      }
      width="$2"
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

if ! [[ "$width" =~ ^[0-9]+$ ]] || ((width == 0)); then
  printf 'error: WIDTH must be a positive number\n' >&2
  exit 1
fi

for f in "$@"; do
  [[ -r "$f" ]] || {
    printf 'error: cannot read %s\n' "$f" >&2
    exit 1
  }
done

fold -s -w "$width" "$@"
