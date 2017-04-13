#!/usr/bin/env bash
# Split a CSV file into parts, repeating the header row.
# Usage: split-csv.sh [-r ROWS] [-n PARTS] [--force] FILE
# Note: quoted fields may hold commas, but not line breaks.

set -euo pipefail

rows=0
parts=0
force=0

usage() {
  cat <<'EOF'
Cut a CSV into smaller files with the same header.
Usage: split-csv.sh [-r ROWS] [-n PARTS] [--force] FILE

  -r ROWS     data rows per part
  -n PARTS    number of parts to make
  --force     overwrite part files from an earlier run
  -h, --help  show this help

Give one of -r or -n. Parts are named FILE-part-01.csv and so on.
EOF
}

while (($# > 0)); do
  case "$1" in
    -r|--rows)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      rows="$2"; shift ;;
    -n|--parts)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      parts="$2"; shift ;;
    --force) force=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
  shift
done
(($# == 1)) || { printf 'error: give one CSV file\n' >&2; usage >&2; exit 1; }
file="$1"
[[ -r "$file" ]] || { printf 'error: cannot read %s\n' "$file" >&2; exit 1; }
[[ "$rows" =~ ^[0-9]+$ && "$parts" =~ ^[0-9]+$ ]] || { printf 'error: ROWS and PARTS must be numbers\n' >&2; exit 1; }
((rows > 0 || parts > 0)) || { printf 'error: give -r ROWS or -n PARTS\n' >&2; exit 1; }
((rows == 0 || parts == 0)) || { printf 'error: use -r or -n, not both\n' >&2; exit 1; }

total=$(awk 'END { print (NR > 0 ? NR - 1 : 0) }' "$file")
((total > 0)) || { printf 'error: %s has no data rows\n' "$file" >&2; exit 1; }
if ((parts > 0)); then
  rows=$(( (total + parts - 1) / parts ))
else
  parts=$(( (total + rows - 1) / rows ))
fi

prefix="${file%.csv}"
if ((!force)); then
  i=1
  while ((i <= parts)); do
    target=$(printf '%s-part-%02d.csv' "$prefix" "$i")
    [[ ! -e "$target" ]] || { printf 'error: %s exists. Move it, or add --force.\n' "$target" >&2; exit 1; }
    i=$((i + 1))
  done
fi

printf '✂️  Writing %d part(s) of %d row(s) from %s\n' "$parts" "$rows" "$file" >&2
awk -v prefix="$prefix" -v rows="$rows" '
  NR == 1 { header = $0; next }
  {
    if (count == 0) {
      part++
      out = sprintf("%s-part-%02d.csv", prefix, part)
      printf "%s\n", header > out
    }
    print $0 > out
    count++
    if (count == rows) { close(out); count = 0 }
  }
  END { if (out != "") close(out) }
' "$file"
