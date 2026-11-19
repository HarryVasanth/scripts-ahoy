#!/usr/bin/env bash
set -euo pipefail

# Check names for CNAME targets that may allow a subdomain takeover.
# Usage: takeover-check.sh <name> [name...]
# Needs: dig
# Note: Use the output only for names that you own or may test.

usage() {
  printf 'Usage: %s <name> [name...]\n' "${0##*/}"
  printf '  Reads names from stdin when you give no names.\n'
  printf 'Example: printf "%%s\\n" www.example.com | %s\n' "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi
command -v dig > /dev/null 2>&1 \
  || {
    printf 'Error: dig is not installed. Try: brew install bind or apt install dnsutils.\n' >&2
    exit 1
  }

names=()
if (($# > 0)); then
  names=("$@")
else
  [[ -t 0 ]] && {
    printf 'Error: give a name or pipe a list.\n' >&2
    exit 1
  }
  while IFS= read -r line; do
    [[ -n $line ]] && names+=("$line")
  done
fi
((${#names[@]} > 0)) || {
  printf 'Error: no names to check.\n' >&2
  exit 1
}

candidates=0
for name in "${names[@]}"; do
  [[ $name =~ ^[A-Za-z0-9._-]+$ ]] || {
    printf '⚠️  Skip invalid name "%s".\n' "$name" >&2
    continue
  }
  target=$(dig +short CNAME "$name" 2> /dev/null | tail -n 1 | sed 's/\.$//') || target=""
  if [[ -z $target ]]; then
    printf '   ➖ %s has no CNAME.\n' "$name"
    continue
  fi
  addresses=$(
    dig +short A "$target" 2> /dev/null
    dig +short AAAA "$target" 2> /dev/null
  ) || addresses=""
  service=0
  case "$target" in
    *github.io | *herokuapp.com | *s3.amazonaws.com | *cloudfront.net | *azurewebsites.net | *trafficmanager.net | *fastly.net | *pantheonsite.io | *wordpress.com)
      service=1
      ;;
  esac
  if [[ -z $addresses ]]; then
    printf '   ⚠️  %s → %s does not resolve. Possible takeover.\n' "$name" "$target"
    candidates=$((candidates + 1))
  elif ((service == 1)); then
    printf '   ❔ %s → %s uses a shared service. Check the claim.\n' "$name" "$target"
    candidates=$((candidates + 1))
  else
    printf '   ✅ %s → %s resolves.\n' "$name" "$target"
  fi
done

printf '📊 %d name(s) need a manual check.\n' "$candidates"
