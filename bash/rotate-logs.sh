#!/usr/bin/env bash
# Rotate a log file once it passes a size limit.
# Usage: rotate-logs.sh [-n COUNT] [-s SIZE] [--dry-run] FILE...
# Note: the live file is emptied after a good gzip. Add --dry-run to preview.

set -euo pipefail

count=5
limit=$((10 * 1024 * 1024))
dry=0

usage() {
  cat <<'EOF'
Compress a log file and keep a few old copies.
Usage: rotate-logs.sh [-n COUNT] [-s SIZE] [--dry-run] FILE...

  -n COUNT    keep this many old copies (default: 5)
  -s SIZE     rotate above this size, like 500k or 10M (default: 10M)
  --dry-run   show the plan and change nothing
  -h, --help  show this help

Old copies are named FILE.1.gz, FILE.2.gz and so on.
EOF
}

while (($# > 0)); do
  case "$1" in
    -n|--count)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      count="$2"; shift 2 ;;
    -s|--size)
      (($# >= 2)) || { printf 'error: %s needs a value\n' "$1" >&2; exit 1; }
      limit="$2"; shift 2 ;;
    --dry-run) dry=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
done
(($# > 0)) || { printf 'error: give at least one log file\n' >&2; usage >&2; exit 1; }
[[ "$count" =~ ^[1-9][0-9]*$ ]] || { printf 'error: COUNT must be a positive number\n' >&2; exit 1; }

# Turn a size like 10M into bytes.
if [[ "$limit" =~ ^[0-9]+[kKmMgG]?$ ]]; then
  amount="${limit%[kKmMgG]}"
  unit="${limit#"$amount"}"
  case "$unit" in
    k|K) limit=$((amount * 1024)) ;;
    m|M) limit=$((amount * 1024 * 1024)) ;;
    g|G) limit=$((amount * 1024 * 1024 * 1024)) ;;
    *) limit=$amount ;;
  esac
else
  printf 'error: SIZE looks wrong. Use a number, then k, M or G.\n' >&2
  exit 1
fi
for f in "$@"; do
  if [[ ! -f "$f" ]]; then
    printf '⚠️  Skip %s: not a file\n' "$f" >&2
    continue
  fi
  used=$(( $(wc -c < "$f") ))
  if ((used < limit)); then
    printf '✅ %s is under the limit\n' "$f" >&2
    continue
  elif ((dry)); then
    printf '📝 Would rotate %s and keep %d old copy/copies\n' "$f" "$count" >&2
    continue
  fi
  i=$((count - 1))
  while ((i >= 1)); do
    if [[ -f "$f.$i.gz" ]]; then
      mv -f -- "$f.$i.gz" "$f.$((i + 1)).gz"
    fi
    i=$((i - 1))
  done
  gzip -c -- "$f" > "$f.1.gz"
  : > "$f"
  printf '🗜️  Rotated %s\n' "$f" >&2
done
