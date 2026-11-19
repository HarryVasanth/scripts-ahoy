#!/usr/bin/env bash
set -euo pipefail

# Show the public IP address that this machine uses.
# Usage: public-ip.sh [--4|--6]
# Needs: curl

usage() {
  printf 'Usage: %s [--4|--6]\n' "${0##*/}"
  printf '  --4  Show the IPv4 address only.\n'
  printf '  --6  Show the IPv6 address only.\n'
}

family=""
for arg in "$@"; do
  case "$arg" in
    -h | --help)
      usage
      exit 0
      ;;
    -4 | --4) family=4 ;;
    -6 | --6) family=6 ;;
    *)
      printf 'Error: unknown option "%s".\n' "$arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v curl > /dev/null 2>&1; then
  printf 'Error: curl is not installed.\n' >&2
  printf 'Install it: brew install curl (macOS) or apt install curl (Debian).\n' >&2
  exit 1
fi

endpoints=(https://icanhazip.com https://api.ipify.org https://ifconfig.co)

lookup() {
  local fam=$1 url answer
  for url in "${endpoints[@]}"; do
    if ! answer=$(curl "-$fam" -fsS --max-time 5 "$url" 2> /dev/null); then
      continue
    fi
    answer=$(printf '%s' "$answer" | tr -d '[:space:]')
    if [[ $fam == 4 && $answer =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
      printf '%s (%s)' "$answer" "$url"
      return 0
    fi
    if [[ $fam == 6 && $answer == *:* && $answer != *" "* ]]; then
      printf '%s (%s)' "$answer" "$url"
      return 0
    fi
  done
  return 1
}

failed=0
if [[ -z $family || $family == 4 ]]; then
  if result=$(lookup 4); then
    printf '🌐 IPv4: %s\n' "$result"
  else
    printf '🌐 IPv4: no answer from the test services.\n' >&2
    failed=1
  fi
fi
if [[ -z $family || $family == 6 ]]; then
  if result=$(lookup 6); then
    printf '🌐 IPv6: %s\n' "$result"
  else
    printf '🌐 IPv6: no answer. The network may not route IPv6.\n' >&2
    failed=1
  fi
fi

if [[ -n $family ]] && ((failed == 1)); then
  exit 1
fi
