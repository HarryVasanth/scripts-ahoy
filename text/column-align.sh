#!/usr/bin/env bash
# Line up columns of text for a clean plain-text table.
# Usage: column-align.sh [-s SEP] [-r] [FILE]
# Note: SEP is a regular expression. Escape characters like | with a backslash.

set -euo pipefail

sep=""
right=0
file=""

usage() {
  cat << 'EOF'
Pad fields so that every column lines up.
Usage: column-align.sh [-s SEP] [-r] [FILE]

  -s SEP      field separator (default: runs of spaces or tabs)
  -r, --right align values to the right (numbers read better)
  -h, --help  show this help

Reads standard input when no FILE is given.
EOF
}

while (($# > 0)); do
  case "$1" in
    -s | --sep)
      (($# >= 2)) || {
        printf 'error: %s needs a value\n' "$1" >&2
        exit 1
      }
      sep="$2"
      shift
      ;;
    -r | --right) right=1 ;;
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
  printf 'error: give one file only\n' >&2
  exit 1
}
if (($# == 1)); then
  file="$1"
  [[ -r "$file" ]] || {
    printf 'error: cannot read %s\n' "$file" >&2
    exit 1
  }
fi
align() {
  awk -v sep="$sep" -v right="$right" '
    {
      if (sep == "") {
        n = NF
        for (i = 1; i <= n; i++) field[i] = $i
      } else {
        n = split($0, field, sep)
      }
      if (n > width_n) width_n = n
      for (i = 1; i <= n; i++) {
        cell[NR, i] = field[i]
        if (length(field[i]) > width[i]) width[i] = length(field[i])
      }
    }
    END {
      for (r = 1; r <= NR; r++) {
        line = ""
        for (c = 1; c <= width_n; c++) {
          v = ((r, c) in cell) ? cell[r, c] : ""
          pad = ""
          for (k = length(v); k < width[c]; k++) pad = pad " "
          if (c > 1) line = line "  "
          if (right) line = line pad v
          else line = line v pad
        }
        sub(/[ \t]+$/, "", line)
        print line
      }
    }
  '
}

if [[ -n "$file" ]]; then
  align < "$file"
else
  align
fi
