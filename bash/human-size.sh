#!/usr/bin/env bash
# Convert bytes to a human size, or a human size back to bytes.
# Usage: human-size.sh [-b] VALUE

set -euo pipefail

to_bytes=0

usage() {
  cat <<'EOF'
Convert between bytes and human sizes.
Usage: human-size.sh [-b] VALUE

  -b, --bytes   convert a human size back to bytes
  -h, --help    show this help

Sizes use powers of 1024: B, KiB, MiB, GiB, TiB.
Short forms such as K, MB and GB are also accepted.

Example: human-size.sh 1073741824
Example: human-size.sh -b 1.5GiB
EOF
}

while (($# > 0)); do
  case "$1" in
    -b|--bytes) to_bytes=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) break ;;
  esac
done

(($# == 1)) || { printf 'error: give one value\n' >&2; usage >&2; exit 1; }
value="$1"

if ((to_bytes)); then
  num=$(printf '%s' "$value" | tr -cd '0-9.')
  unit=$(printf '%s' "$value" | tr -d '0-9. ' | tr '[:lower:]' '[:upper:]')
  [[ -n "$num" ]] || { printf 'error: no number in %s\n' "$value" >&2; exit 1; }
  case "$unit" in
    ""|B) mult=1 ;;
    K|KB|KIB) mult=1024 ;;
    M|MB|MIB) mult=$((1024 * 1024)) ;;
    G|GB|GIB) mult=$((1024 * 1024 * 1024)) ;;
    T|TB|TIB) mult=$((1024 * 1024 * 1024 * 1024)) ;;
    *) printf 'error: unknown unit %s\n' "$unit" >&2; exit 1 ;;
  esac
  awk -v n="$num" -v m="$mult" 'BEGIN { printf "%.0f\n", n * m }'
else
  [[ "$value" =~ ^[0-9]+$ ]] ||
    { printf 'error: %s is not a whole number of bytes\n' "$value" >&2; exit 1; }
  awk -v b="$value" 'BEGIN {
    split("B KiB MiB GiB TiB PiB", u, " ")
    i = 1
    while (b >= 1024 && i < 6) { b /= 1024; i++ }
    if (i == 1) printf "%d %s\n", b, u[i]
    else printf "%.2f %s\n", b, u[i]
  }'
fi
