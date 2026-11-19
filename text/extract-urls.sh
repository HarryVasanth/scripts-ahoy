#!/usr/bin/env bash
# Pull URLs out of text.
# Usage: extract-urls.sh [-a] [FILE...]

set -euo pipefail

keep=0
files=()

usage() {
  cat << 'EOF'
Find http and https URLs in text.
Usage: extract-urls.sh [-a] [FILE...]

  -a, --all     keep the input order and keep repeats
  -h, --help    show this help

By default each URL is printed once, sorted.
Reads standard input when no FILE is given.
EOF
}

while (($# > 0)); do
  case "$1" in
    -a | --all)
      keep=1
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

if ((${#files[@]} > 0)); then
  for f in "${files[@]}"; do
    [[ -r "$f" ]] || {
      printf 'error: cannot read %s\n' "$f" >&2
      exit 1
    }
  done
fi

pattern='https?://[^[:space:]<>"]+'

if ((${#files[@]} > 0)); then
  found=$(grep -Eoh "$pattern" "${files[@]}" || true)
else
  found=$(grep -Eoh "$pattern" || true)
fi

if [[ -z "$found" ]]; then
  printf '🔍 No URLs found\n' >&2
  exit 0
fi

# Drop trailing punctuation that belongs to the sentence, not the URL.
found=$(printf '%s\n' "$found" | sed 's/[.,;:!?)]*$//')

if ((keep)); then
  printf '%s\n' "$found"
else
  printf '%s\n' "$found" | sort -u
fi
