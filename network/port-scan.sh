#!/usr/bin/env bash
set -euo pipefail

# Scan a port range on one host that you own.
# Usage: port-scan.sh [--yes] <host> <start>-<end>
# Needs: nc
# Note: Scan only a host that you own or may test. The range is limited to 1024 ports.

usage() {
  printf 'Usage: %s [--yes] <host> <start>-<end>\n' "${0##*/}"
  printf '  --yes  Do not ask for confirmation.\n'
  printf 'Example: %s 192.168.1.10 1-1024\n' "${0##*/}"
}
ask=1 args=()
for arg in "$@"; do
  case "$arg" in
    -h | --help)
      usage
      exit 0
      ;;
    --yes) ask=0 ;;
    -*)
      printf 'Error: unknown option "%s".\n' "$arg" >&2
      exit 1
      ;;
    *) args+=("$arg") ;;
  esac
done
if ((${#args[@]} != 2)); then
  usage >&2
  exit 1
fi
host=${args[0]} range=${args[1]}
[[ $host =~ ^[A-Za-z0-9._:-]+$ ]] \
  || {
    printf 'Error: "%s" is not a valid host.\n' "$host" >&2
    exit 1
  }
[[ $range =~ ^([0-9]+)-([0-9]+)$ ]] \
  || {
    printf 'Error: use a range such as 1-1024.\n' >&2
    exit 1
  }
start=${BASH_REMATCH[1]} end=${BASH_REMATCH[2]}
((start >= 1 && end <= 65535 && start <= end)) \
  || {
    printf 'Error: the range must be 1-65535 and start below end.\n' >&2
    exit 1
  }
((end - start + 1 <= 1024)) \
  || {
    printf 'Error: the range is too large. Use 1024 ports or fewer.\n' >&2
    exit 1
  }
command -v nc > /dev/null 2>&1 || {
  printf 'Error: nc is not installed.\n' >&2
  exit 1
}

printf '⚠️  You are about to scan %s:%s-%s.\n' "$host" "$start" "$end" >&2
printf '   Scan only a host that you own or may test.\n' >&2
if ((ask == 1)); then
  printf 'Continue? [y/N] '
  read -r reply || reply=""
  case "$reply" in
    y | Y | yes | YES) ;;
    *)
      printf 'Cancelled.\n'
      exit 1
      ;;
  esac
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
running=0
for ((port = start; port <= end; port++)); do
  (nc -z -w 1 "$host" "$port" > /dev/null 2>&1 && printf '%s\n' "$port" >> "$tmp") &
  running=$((running + 1))
  if ((running >= 64)); then
    wait
    running=0
  fi
done
wait

printf '🔎 %s ports %s-%s\n' "$host" "$start" "$end"
if [[ -s $tmp ]]; then
  while IFS= read -r port; do printf '   ✅ %s open\n' "$port"; done < <(sort -n "$tmp")
  printf '📊 %s open.\n' "$(wc -l < "$tmp" | tr -d ' ')"
else
  printf '   No open ports in this range.\n'
fi
