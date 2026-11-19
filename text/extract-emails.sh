#!/usr/bin/env bash
# Pull email addresses out of text files.
# Usage: extract-emails.sh [-a] [-c] [FILE...]
# Note: reads standard input when no FILE is given.

set -euo pipefail

all=0
counts=0
files=()

usage() {
  cat << 'EOF'
Find email addresses in text.
Usage: extract-emails.sh [-a] [-c] [FILE...]

  -a, --all     keep the input order and keep repeats
  -c, --count   count how often each address appears
  -h, --help    show this help

By default the script prints each address once, sorted.
EOF
}

while (($# > 0)); do
  case "$1" in
    -a | --all)
      all=1
      shift
      ;;
    -c | --count)
      counts=1
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
    *)
      files+=("$1")
      shift
      ;;
  esac
done

((all == 0 || counts == 0)) || {
  printf 'error: use -a or -c, not both\n' >&2
  exit 1
}

if ((${#files[@]} > 0)); then
  for f in "${files[@]}"; do
    [[ -r "$f" ]] || {
      printf 'error: cannot read %s\n' "$f" >&2
      exit 1
    }
  done
fi

pattern='[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}'

if ((${#files[@]} > 0)); then
  found=$(grep -Eoh "$pattern" "${files[@]}" || true)
else
  found=$(grep -Eoh "$pattern" || true)
fi

if [[ -z "$found" ]]; then
  printf '🔍 No email addresses found\n' >&2
  exit 0
fi

if ((counts)); then
  printf '%s\n' "$found" | sort | uniq -c | sort -rn
elif ((all)); then
  printf '%s\n' "$found"
else
  printf '%s\n' "$found" | sort -u
fi
