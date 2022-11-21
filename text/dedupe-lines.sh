#!/usr/bin/env bash
# Remove duplicate lines from text while keeping the first order.
# Usage: dedupe-lines.sh [-c] [-d] [FILE]

set -euo pipefail

mode="unique"
file=""

usage() {
  cat <<'EOF'
Drop repeated lines, or show only the repeats.
Usage: dedupe-lines.sh [-c] [-d] [FILE]

  -c, --count   keep the order and add a count before each line
  -d, --dupe    print only lines that appear more than once
  -h, --help    show this help

Reads standard input when no FILE is given.
EOF
}

while (($# > 0)); do
  case "$1" in
    -c|--count) mode="count"; shift ;;
    -d|--dupe) mode="dupe"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
done

(($# <= 1)) || { printf 'error: give one file only\n' >&2; exit 1; }
if (($# == 1)); then
  file="$1"
  [[ -r "$file" ]] || { printf 'error: cannot read %s\n' "$file" >&2; exit 1; }
fi

run() {
  case "$mode" in
    count)
      awk '{ total[$0]++; if (!seen[$0]++) order[++n] = $0 }
        END { for (i = 1; i <= n; i++) printf "%7d %s\n", total[order[i]], order[i] }'
      ;;
    dupe)
      awk 'seen[$0]++' | awk '!done[$0]++'
      ;;
    *)
      awk '!seen[$0]++'
      ;;
  esac
}

if [[ -n "$file" ]]; then
  run < "$file"
else
  run
fi
