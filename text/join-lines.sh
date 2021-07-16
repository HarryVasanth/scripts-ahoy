#!/usr/bin/env bash
# Join all lines into one line with a separator.
# Usage: join-lines.sh [-s SEP] [FILE...]

set -euo pipefail

sep=" "

usage() {
  cat <<'EOF'
Join lines into a single line.
Usage: join-lines.sh [-s SEP] [FILE...]

  -s, --separator SEP   text between the lines (default: a space)
  -h, --help            show this help

Reads standard input when no FILE is given.
Use quotes for a space or an empty separator.

Example: join-lines.sh -s ', ' names.txt
EOF
}

while (($# > 0)); do
  case "$1" in
    -s|--separator)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      sep="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
done

for f in "$@"; do
  [[ -r "$f" ]] || { printf 'error: cannot read %s\n' "$f" >&2; exit 1; }
done

awk -v sep="$sep" '
  BEGIN { first = 1 }
  { if (!first) printf "%s", sep; printf "%s", $0; first = 0 }
  END { if (!first) printf "\n" }
' "$@"
