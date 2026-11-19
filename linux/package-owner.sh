#!/usr/bin/env bash
set -euo pipefail

# Shows which package owns a file, using apt or rpm.
# Usage: package-owner [-h] FILE
# Needs: dpkg or rpm

if [[ $(uname -s) != Linux ]]; then
  printf 'Error: this tool needs Linux.\n' >&2
  exit 1
fi

show_help() {
  cat << 'EOF'
package-owner - show which package owns a file.

Usage: package-owner FILE

On a Debian system the tool uses dpkg. On a Red Hat system it uses rpm. The
path must exist. The tool reports when no package owns the file.
EOF
}

case $# in
  0)
    printf 'Error: give a file path.\n' >&2
    show_help >&2
    exit 1
    ;;
  1)
    if [[ $1 == -h || $1 == --help ]]; then
      show_help
      exit 0
    fi
    ;;
  *)
    printf 'Error: give one file path only.\n' >&2
    exit 1
    ;;
esac

file=$1
if [[ ! -e "$file" ]]; then
  printf 'Error: no such path: %s\n' "$file" >&2
  exit 1
fi

path=$(readlink -f "$file" 2> /dev/null || printf '%s' "$file")

if command -v dpkg > /dev/null 2>&1; then
  if owner=$(dpkg -S "$path" 2> /dev/null); then
    printf '📦 %s\n' "$owner"
    exit 0
  fi
  printf 'No package owns %s (dpkg).\n' "$path"
  exit 1
fi

if command -v rpm > /dev/null 2>&1; then
  if owner=$(rpm -qf "$path" 2> /dev/null); then
    printf '📦 %s\n' "$owner"
    exit 0
  fi
  printf 'No package owns %s (rpm).\n' "$path"
  exit 1
fi

printf 'Error: neither dpkg nor rpm is installed.\n' >&2
exit 1
