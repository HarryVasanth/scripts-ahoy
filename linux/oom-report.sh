#!/usr/bin/env bash
# Show recent out-of-memory kills on a Linux host.
# Usage: oom-report.sh [-n COUNT]
# Needs: dmesg or journalctl
# Note: dmesg may need root. The script never runs sudo for you.

set -euo pipefail

count=10
while getopts ':n:h' opt; do
  case "$opt" in
    n) count=$OPTARG ;;
    h)
      sed -n '2,4p' "$0" | sed 's/^# //'
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

if [[ "$(uname -s)" != "Linux" ]]; then
  printf '[-] This script only runs on Linux. 🐧\n' >&2
  exit 1
fi
if ! [[ "$count" =~ ^[0-9]+$ ]] || ((count < 1)); then
  printf '[-] COUNT must be a positive number.\n' >&2
  exit 2
fi

tmp=$(mktemp "${TMPDIR:-/tmp}/oom-report.XXXXXX")
trap 'rm -f "$tmp"' EXIT

if command -v journalctl >/dev/null 2>&1 && journalctl -k -n 1 >/dev/null 2>&1; then
  journalctl -k --since '30 days ago' --no-pager >"$tmp" 2>/dev/null || true
  source_name="journalctl"
else
  dmesg >"$tmp" 2>/dev/null || true
  source_name="dmesg"
fi

if [[ ! -s "$tmp" ]]; then
  printf '[-] No kernel log available. Try again with sudo. 🔒\n' >&2
  exit 1
fi

printf '🔎 Recent OOM events from %s:\n\n' "$source_name"
matches=$(grep -Ei 'out of memory|oom-killer|killed process' "$tmp" | tail -n "$count" || true)

if [[ -z "$matches" ]]; then
  printf '✅ No out-of-memory kills in the last 30 days.\n'
  exit 0
fi

printf '%s\n' "$matches"
printf '\n[*] %s line(s) shown. Check memory pressure with: free -h\n' \
  "$(printf '%s\n' "$matches" | wc -l | tr -d ' ')"
