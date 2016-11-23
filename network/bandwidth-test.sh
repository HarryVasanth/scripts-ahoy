#!/usr/bin/env bash
set -euo pipefail

# Measure download speed against a public test file.
# Usage: bandwidth-test.sh [--size <megabytes>] [url]
# Needs: curl, awk
# Note: This moves real data. The default test is 25 MB.

usage() {
  printf 'Usage: %s [--size <megabytes>] [url]\n' "${0##*/}"
  printf '  --size  Data to download in MB. Default: 25\n'
  printf '  url     A file to download. Default: the Cloudflare speed test.\n'
}

size=25
args=()
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --size) size="__next__" ;;
    -*) printf 'Error: unknown option "%s".\n' "$arg" >&2; usage >&2; exit 1 ;;
    *)
      if [[ $size == "__next__" ]]; then
        size=$arg
      else
        args+=("$arg")
      fi
      ;;
  esac
done

if [[ $size == "__next__" || ! $size =~ ^[0-9]+$ ]] || (( size < 1 || size > 500 )); then
  printf 'Error: the size must be a number of MB from 1 to 500.\n' >&2
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  printf 'Error: curl is not installed.\n' >&2
  exit 1
fi

bytes=$(( size * 1000000 ))
url=${args[0]:-"https://speed.cloudflare.com/__down?bytes=$bytes"}

if ! stats=$(curl -sS -L --max-time 180 -o /dev/null \
  -w '%{http_code} %{size_download} %{time_total} %{speed_download}' "$url"); then
  printf 'Error: the download failed. Check the URL and the network.\n' >&2
  exit 1
fi

read -r code got secs rate <<< "$stats"
case "$code" in
  200|206) ;;
  *)
    printf 'Error: the server answered with HTTP %s.\n' "$code" >&2
    exit 1
    ;;
esac

awk -v got="$got" -v secs="$secs" -v rate="$rate" 'BEGIN {
  printf "📥 %.1f MB in %.2f s\n", got / 1048576, secs
  printf "⚡ %.2f Mbit/s (%.2f MB/s)\n", rate * 8 / 1000000, rate / 1048576
}'
