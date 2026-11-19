#!/usr/bin/env bash
# Flatten a simple JSON array of objects into CSV.
# Usage: json-to-csv.sh [FILE]
# Needs: jq

set -euo pipefail

usage() {
  cat << 'EOF'
Turn a JSON array of flat objects into CSV.
Usage: json-to-csv.sh [FILE]

  -h, --help   show this help

The header lists every key, in the order the keys first appear.
Reads standard input when no FILE is given.

Example: json-to-csv.sh users.json > users.csv
EOF
}

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    printf 'error: unknown option %s\n' "$1" >&2
    exit 1
    ;;
esac

(($# <= 1)) || {
  printf 'error: give one file at most\n' >&2
  usage >&2
  exit 1
}
command -v jq > /dev/null 2>&1 \
  || {
    printf 'error: jq is not installed\n  macOS: brew install jq\n  Linux: apt-get install jq\n' >&2
    exit 1
  }

if (($# == 1)); then
  [[ -r "$1" ]] || {
    printf 'error: cannot read %s\n' "$1" >&2
    exit 1
  }
  input="$1"
else
  input="-"
fi

jq -r '
  (if type != "array" then error("top level must be an array") else . end)
  | (map(keys_unsorted) | add // []) as $all
  | (reduce $all[] as $k ([]; if index($k) then . else . + [$k] end)) as $cols
  | ($cols | @csv),
    (.[] | [.[$cols[]]] | @csv)
' "$input"
