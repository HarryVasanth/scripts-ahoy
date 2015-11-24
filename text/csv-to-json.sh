#!/usr/bin/env bash
# Turn a simple CSV file into a JSON array of objects.
# Usage: csv-to-json.sh [--numbers] [FILE]
# Note: the first row must hold the column names.
# Note: quoted fields may hold commas and quotes, but not line breaks.

set -euo pipefail

numbers=0
file=""
usage() {
  cat <<'EOF'
Convert CSV to JSON on standard output.
Usage: csv-to-json.sh [--numbers] [FILE]

  --numbers   write plain numbers for numeric values
  -h, --help  show this help

Reads standard input when no FILE is given.
EOF
}
while (($# > 0)); do
  case "$1" in
    --numbers) numbers=1; shift ;;
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
convert() {
  awk -v numbers="$numbers" '
    function esc(s) {
      gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); gsub(/\t/, "\\t", s)
      return s
    }
    function split_csv(line, cell,   i, c, n, field, quoted) {
      n = 0; field = ""; quoted = 0
      for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)
        if (quoted) {
          if (c != "\"") { field = field c; continue }
          if (substr(line, i + 1, 1) == "\"") { field = field "\""; i++ }
          else quoted = 0
        } else if (c == "\"") quoted = 1
        else if (c == ",") { cell[++n] = field; field = "" }
        else field = field c
      }
      cell[++n] = field
      return n
    }
    NR == 1 {
      sub(/\r$/, "")
      if ($0 == "") { print "error: the first row is empty" > "/dev/stderr"; exit 1 }
      ncols = split_csv($0, name)
      next
    }
    {
      sub(/\r$/, "")
      if ($0 == "") next
      n = split_csv($0, value)
      if (!started) { printf "[\n"; started = 1 } else printf ",\n"
      printf "  {"
      for (i = 1; i <= ncols; i++) {
        if (i > 1) printf ", "
        v = (i <= n) ? value[i] : ""
        printf "\"%s\": ", esc(name[i])
        if (numbers && v ~ /^-?[0-9]+(\.[0-9]+)?$/) printf "%s", v
        else printf "\"%s\"", esc(v)
      }
      printf "}"
    }
    END { if (started) printf "\n]\n"; else printf "[]\n" }
  '
}
if [[ -n "$file" ]]; then convert < "$file"; else convert; fi
