#!/usr/bin/env bash
set -euo pipefail

# Shows the Spotlight indexing status for each volume.
# Usage: spotlight-status [VOLUME] [-h]
# Needs: mdutil

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
spotlight-status - show the Spotlight indexing status.

Usage: spotlight-status [VOLUME]

With no argument the tool checks / and every volume in /Volumes. Some volumes
need sudo for a full answer. Indexing must be on for Spotlight search to work.
EOF
}

volume=
case $# in
  0) ;;
  1)
    if [[ $1 == -h || $1 == --help ]]; then
      show_help
      exit 0
    fi
    volume=$1
    ;;
  *)
    printf 'Error: give one volume at most.\n' >&2
    exit 1
    ;;
esac

show_volume() {
  out=$(mdutil -s "$1" 2>&1) || true
  case "$out" in
    *disabled*) icon='⚠️ ' ;;
    *enabled*) icon='✅' ;;
    *) icon='❔' ;;
  esac
  printf '%s %s\n' "$icon" "$1"
  printf '%s\n' "$out" | sed 's/^[[:space:]]*/   /'
}

if [[ -n "$volume" ]]; then
  show_volume "$volume"
  exit 0
fi

printf '🔎 Spotlight indexing\n'
show_volume /
for vol in /Volumes/*; do
  [[ -d "$vol" ]] || continue
  show_volume "$vol"
done
