#!/usr/bin/env bash
# Pretty-print, compact, or sort a JSON file.
# Usage: json-pretty.sh [-c] [-s] [FILE]
# Needs: jq

set -euo pipefail

compact=0
sortkeys=0
file=""

usage() {
  cat <<'EOF'
Format JSON for reading or for machines.
Usage: json-pretty.sh [-c] [-s] [FILE]

  -c, --compact  put the JSON on one line
  -s, --sort     sort object keys
  -h, --help     show this help

Reads standard input when no FILE is given.
EOF
}

while (($# > 0)); do
  case "$1" in
    -c|--compact) compact=1; shift ;;
    -s|--sort) sortkeys=1; shift ;;
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

if ! command -v jq >/dev/null 2>&1; then
  printf 'error: jq is needed for JSON. Install it with: brew install jq (macOS) or apt install jq (Debian/Ubuntu).\n' >&2
  exit 1
fi

run() {
  if [[ -n "$file" ]]; then
    jq "$@" . "$file"
  else
    jq "$@" .
  fi
}

if ((compact && sortkeys)); then
  run -c -S
elif ((compact)); then
  run -c
elif ((sortkeys)); then
  run -S
else
  run
fi
