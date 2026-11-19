#!/usr/bin/env bash
set -euo pipefail

# Lists the displays and their current resolutions.
# Usage: screen-resolution [-h]
# Needs: system_profiler

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat << 'EOF'
screen-resolution - list displays and their resolutions.

Usage: screen-resolution

The tool reads the display data from system_profiler. It shows each display,
its type, the current resolution and the main display mark.
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

raw=$(system_profiler SPDisplaysDataType 2> /dev/null || true)
if [[ -z "$raw" ]]; then
  printf 'Error: no display data. This Mac may have no active display.\n' >&2
  exit 1
fi

printf '🖥️  Displays\n'
printf '%s\n' "$raw" \
  | grep -E 'Resolution:|UI Looks like:|Display Type:|Main Display:|^ {8}[^ ].*:$' \
  | sed 's/^ */  /'
