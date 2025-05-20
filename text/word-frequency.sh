#!/usr/bin/env bash
# Count the most common words in text.
# Usage: word-frequency.sh [-n COUNT] [-i] [FILE...]
# Note: reads standard input when no FILE is given.

set -euo pipefail

count=20
fold=0
while getopts ':n:ih' opt; do
  case "$opt" in
    n) count=$OPTARG ;;
    i) fold=1 ;;
    h)
      sed -n '2,3p' "$0" | sed 's/^# //'
      exit 0
      ;;
    :)
      printf '[-] -%s needs a value.\n' "$OPTARG" >&2
      exit 2
      ;;
    *)
      printf '[-] Unknown option: -%s\n' "$OPTARG" >&2
      exit 2
      ;;
  esac
done
shift $((OPTIND - 1))

if ! [[ "$count" =~ ^[1-9][0-9]*$ ]]; then
  printf '[-] COUNT must be a positive number.\n' >&2
  exit 2
fi

if (($# > 0)); then
  for file in "$@"; do
    [[ -r $file ]] || { printf '[-] Cannot read: %s\n' "$file" >&2; exit 1; }
  done
  source_text=$(cat "$@")
else
  source_text=$(cat)
fi

if ((fold == 1)); then
  words=$(printf '%s\n' "$source_text" | tr '[:upper:]' '[:lower:]')
else
  words=$source_text
fi

printf '%s\n' "$words" \
  | tr -cs '[:alpha:]' '\n' \
  | sed '/^$/d' \
  | awk '{ total++ } { seen[$0]++ } END { for (w in seen) printf "%d\t%s\n", seen[w], w }' \
  | sort -rn -k1,1 \
  | head -n "$count" \
  | awk -F '\t' '{ printf "%6d  %s\n", $1, $2 }'
