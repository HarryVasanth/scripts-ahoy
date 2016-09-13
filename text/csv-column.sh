#!/usr/bin/env bash
# Select or reorder CSV columns by name.
# Usage: csv-column.sh -c NAME[,NAME...] [FILE]

set -euo pipefail

columns=""

usage() {
  cat <<'EOF'
Pick CSV columns by name and put them in the order you give.
Usage: csv-column.sh -c NAME[,NAME...] [FILE]

  -c, --columns LIST   comma-separated column names
  -h, --help           show this help

The header row is kept. Reads standard input when no FILE is given.
The comma inside quoted fields is not handled.

Example: csv-column.sh -c city,name people.csv
EOF
}

while (($# > 0)); do
  case "$1" in
    -c|--columns)
      (($# >= 2)) || { printf 'error: %s needs a list\n' "$1" >&2; exit 1; }
      columns="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
done

[[ -n "$columns" ]] || { printf 'error: give the columns with -c\n' >&2; usage >&2; exit 1; }
(($# <= 1)) || { printf 'error: give one file at most\n' >&2; usage >&2; exit 1; }

# shellcheck disable=SC2016  # $1 and $i are awk fields, not shell variables.
program='
  BEGIN { n = split(want, w, ","); for (j = 1; j <= n; j++) gsub(/^[ \t]+|[ \t]+$/, "", w[j]) }
  NR == 1 {
    for (i = 1; i <= NF; i++) {
      name = $i
      gsub(/^[ \t]+|[ \t]+$/, "", name)
      h[name] = i
    }
    for (j = 1; j <= n; j++) {
      if (!(w[j] in h)) {
        printf "error: no column named %s\n", w[j] > "/dev/stderr"
        bad = 1
        exit 1
      }
      idx[j] = h[w[j]]
    }
  }
  {
    for (j = 1; j <= n; j++) printf "%s%s", (j > 1 ? "," : ""), $idx[j]
    printf "\n"
  }
'

if (($# == 1)); then
  [[ -r "$1" ]] || { printf 'error: cannot read %s\n' "$1" >&2; exit 1; }
  awk -F, -v want="$columns" "$program" "$1"
else
  awk -F, -v want="$columns" "$program"
fi
