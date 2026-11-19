#!/usr/bin/env bash
# Sort CSV rows by a column and keep the header on top.
# Usage: sort-csv.sh [-c COLUMN] [-n] [-r] [FILE]

set -euo pipefail

column=""
numeric=0
reverse=0

usage() {
  cat << 'EOF'
Sort CSV rows by one column.
Usage: sort-csv.sh [-c COLUMN] [-n] [-r] [FILE]

  -c, --column COLUMN   column name or number (default: the first column)
  -n, --numeric         compare the column as numbers
  -r, --reverse         sort from high to low
  -h, --help            show this help

The header row stays first. Reads standard input when no FILE is given.
The comma inside quoted fields is not handled.
EOF
}

while (($# > 0)); do
  case "$1" in
    -c | --column)
      (($# >= 2)) || {
        printf 'error: %s needs a column\n' "$1" >&2
        exit 1
      }
      column="$2"
      shift 2
      ;;
    -n | --numeric)
      numeric=1
      shift
      ;;
    -r | --reverse)
      reverse=1
      shift
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

(($# <= 1)) || {
  printf 'error: give one file at most\n' >&2
  usage >&2
  exit 1
}
if (($# == 1)); then
  [[ -r "$1" ]] || {
    printf 'error: cannot read %s\n' "$1" >&2
    exit 1
  }
  file="$1"
else
  tmp=$(mktemp "${TMPDIR:-/tmp}/sort-csv.XXXXXX") || exit 1
  trap 'rm -f "$tmp"' EXIT
  cat > "$tmp"
  file="$tmp"
fi

header=$(head -n 1 "$file")
[[ -n "$header" ]] || {
  printf 'error: the input has no header row\n' >&2
  exit 1
}

if [[ "$column" =~ ^[0-9]+$ ]]; then
  idx="$column"
else
  idx=$(printf '%s\n' "$header" | awk -F, -v name="${column:-1}" '
    { for (i = 1; i <= NF; i++) {
        field = $i
        gsub(/^[ \t]+|[ \t]+$/, "", field)
        if (field == name) { print i; exit }
      } }')
  [[ -n "$idx" ]] || {
    printf 'error: no column named %s\n' "${column:-1}" >&2
    exit 1
  }
fi

set -- -t, -k "$idx,$idx"
((numeric)) && set -- "$@" -n
((reverse)) && set -- "$@" -r

head -n 1 "$file"
tail -n +2 "$file" | sort "$@"
