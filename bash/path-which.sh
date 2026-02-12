#!/usr/bin/env bash
# Show every PATH match for a command, not just the first.
# Usage: path-which.sh COMMAND...

set -euo pipefail

(($# > 0)) || { printf 'error: give at least one command\n' >&2; exit 1; }

status=0
for cmd in "$@"; do
  printf '🔎 %s\n' "$cmd"

  if [[ "$cmd" == */* ]]; then
    if [[ -x "$cmd" && ! -d "$cmd" ]]; then
      printf '  1. %s\n' "$cmd"
    else
      printf '  ❌ no executable match\n'
      status=1
    fi
    continue
  fi

  found=0
  oldifs=$IFS
  IFS=:
  set -f
  for dir in $PATH; do
    if [[ -z "$dir" ]]; then
      dir="."
    fi
    if [[ -x "$dir/$cmd" && ! -d "$dir/$cmd" ]]; then
      found=$((found + 1))
      printf '  %d. %s\n' "$found" "$dir/$cmd"
    fi
  done
  set +f
  IFS=$oldifs

  if ((found == 0)); then
    printf '  ❌ not found on PATH\n'
    status=1
  fi
done

exit "$status"
