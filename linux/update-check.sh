#!/usr/bin/env bash
set -euo pipefail

# Counts the package updates that are available.
# Usage: update-check [-h]
# Needs: one of apt-get, dnf, pacman, zypper, apk
# Note: the tool reads the package index only. It changes nothing.

if [[ $(uname -s) != Linux ]]; then
  printf 'Error: this tool needs Linux.\n' >&2
  exit 1
fi

show_help() {
  cat << 'EOF'
update-check - count available package updates.

Usage: update-check

The tool detects the package manager and prints the number of updates.
No package is installed and no index is refreshed. A stale index can give
a low count, so refresh it first when the number looks wrong.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      printf 'Error: unknown argument: %s\n' "$arg" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

count=""
hint=""

if command -v apt-get > /dev/null 2>&1; then
  count=$(apt-get -s -o Debug::NoLocking=1 upgrade 2> /dev/null | grep -c '^Inst' || true)
  hint='apt list --upgradable'
elif command -v dnf > /dev/null 2>&1; then
  count=$(dnf -q check-update 2> /dev/null \
    | awk 'NF >= 3 && $1 ~ /\./ {n++} END {print n + 0}')
  hint='dnf list updates'
elif command -v pacman > /dev/null 2>&1; then
  count=$(pacman -Qu 2> /dev/null | wc -l | tr -d ' ')
  hint='pacman -Qu'
elif command -v zypper > /dev/null 2>&1; then
  count=$(zypper -q lu 2> /dev/null | awk 'NF >= 3 && $1 ~ /^\|/ {n++} END {print n + 0}')
  hint='zypper list-updates'
elif command -v apk > /dev/null 2>&1; then
  count=$(apk version -l '<' 2> /dev/null | grep -vc '^Installed' || true)
  hint='apk version -l "<"'
else
  printf 'Error: no supported package manager found.\n' >&2
  exit 1
fi

if [[ -z "$count" ]]; then
  printf 'Error: the package manager gave no result. Run it by hand to see why.\n' >&2
  exit 1
fi

printf 'Updates available: %s\n' "$count"
if [[ "$count" -gt 0 ]]; then
  printf '📦 See the list with: %s\n' "$hint"
else
  printf '✅ The system is up to date.\n'
fi
