#!/usr/bin/env bash
set -euo pipefail

# Measure download and upload throughput with curl.
# Usage: speed-test.sh [--size <megabytes>]
# Needs: curl, dd, awk
# Note: This moves real data to and from the Cloudflare speed test service.

usage() {
  printf 'Usage: %s [--size <megabytes>]\n  --size  Data per direction in MB. Default: 10\n' "${0##*/}"
}
size=10
while (( $# > 0 )); do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --size)
      [[ $# -ge 2 ]] || { printf 'Error: --size needs a value.\n' >&2; exit 1; }
      size=$2
      shift 2
      ;;
    *) printf 'Error: unknown argument "%s".\n' "$1" >&2; exit 1 ;;
  esac
done
[[ $size =~ ^[1-9][0-9]*$ ]] \
  || { printf 'Error: size must be from 1 to 100 MB.\n' >&2; exit 1; }
(( size <= 100 )) \
  || { printf 'Error: size must be from 1 to 100 MB.\n' >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { printf 'Error: curl is not installed.\n' >&2; exit 1; }
command -v dd >/dev/null 2>&1 || { printf 'Error: dd is not installed.\n' >&2; exit 1; }

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
dd if=/dev/zero of="$tmp" bs=1000000 count="$size" 2>/dev/null

bytes=$(( size * 1000000 ))
printf '⏱️  Testing %s MB per direction...\n' "$size" >&2
down=$(curl -sS -L -o /dev/null --max-time 180 \
  -w '%{speed_download}' "https://speed.cloudflare.com/__down?bytes=$bytes") \
  || { printf 'Error: the download test failed.\n' >&2; exit 1; }
up=$(curl -sS -o /dev/null --max-time 180 -X POST \
  --data-binary "@$tmp" -w '%{speed_upload}' "https://speed.cloudflare.com/__up") \
  || { printf 'Error: the upload test failed.\n' >&2; exit 1; }

awk -v down="$down" -v up="$up" 'BEGIN {
  printf "📥 Download: %.2f Mbit/s (%.2f MB/s)\n", down * 8 / 1000000, down / 1048576
  printf "📤 Upload:   %.2f Mbit/s (%.2f MB/s)\n", up * 8 / 1000000, up / 1048576
}'
