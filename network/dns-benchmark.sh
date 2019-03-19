#!/usr/bin/env bash
set -euo pipefail

# Time DNS answers from several public resolvers.
# Usage: dns-benchmark.sh [domain] [resolver...]
# Needs: dig
# Note: Each resolver gets three queries. A slow or blocked resolver is skipped.

usage() {
  printf 'Usage: %s [domain] [resolver...]\n' "${0##*/}"
  printf '  domain     Name to query. Default: example.com\n'
  printf '  resolver   One or more name servers. Default: four public servers.\n'
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

if ! command -v dig >/dev/null 2>&1; then
  printf 'Error: dig is not installed.\n' >&2
  printf 'Install it: brew install bind (macOS) or apt install dnsutils (Debian).\n' >&2
  exit 1
fi

domain=${1:-example.com}
if [[ $# -gt 1 ]]; then
  shift
  resolvers=("$@")
else
  resolvers=(1.1.1.1 8.8.8.8 9.9.9.9 208.67.222.222)
fi
if [[ ! $domain =~ ^[A-Za-z0-9._-]+$ ]]; then
  printf 'Error: "%s" is not a valid domain.\n' "$domain" >&2
  exit 1
fi

TIMEFORMAT='%R'
export LC_ALL=C
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

printf '⏱️  DNS timing for %s (average of 3 queries)\n' "$domain"
for resolver in "${resolvers[@]}"; do
  answer=$(dig +short +time=2 +tries=1 "@$resolver" "$domain" A 2>/dev/null) || answer=""
  if [[ -z $answer ]]; then
    printf '   ⚠️  %s gave no answer. Skipped.\n' "$resolver" >&2
    continue
  fi
  total=0
  for _ in 1 2 3; do
    elapsed=$( { time dig +short +time=2 +tries=1 "@$resolver" "$domain" A >/dev/null 2>&1; } 2>&1 ) || elapsed=""
    total=$(awk -v a="$total" -v b="$elapsed" 'BEGIN { printf "%.3f", a + b }')
  done
  average=$(awk -v t="$total" 'BEGIN { printf "%.1f", t / 3 * 1000 }')
  printf '%s %s\n' "$average" "$resolver" >> "$tmp"
done

if [[ ! -s $tmp ]]; then
  printf 'Error: no resolver gave an answer.\n' >&2
  exit 1
fi

sort -n "$tmp" | awk '{
  rank++
  mark = "  "
  if (rank == 1) mark = "🥇"
  if (rank == 2) mark = "🥈"
  if (rank == 3) mark = "🥉"
  printf "   %s %7s ms  %s\n", mark, $1, $2
}'
