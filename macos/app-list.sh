#!/usr/bin/env bash
set -euo pipefail

# Lists installed applications and their versions.
# Usage: app-list [FILTER] [-h]
# Needs: defaults

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
app-list - list installed applications and their versions.

Usage: app-list [FILTER]

The tool reads /Applications, /Applications/Utilities and ~/Applications.
FILTER keeps only names that contain the text, in any case. The version comes
from CFBundleShortVersionString.
EOF
}

filter=
case $# in
  0) ;;
  1)
    if [[ $1 == -h || $1 == --help ]]; then
      show_help
      exit 0
    fi
    filter=$1
    ;;
  *)
    printf 'Error: give one filter at most.\n' >&2
    exit 1
    ;;
esac

printf '📱 Applications\n'
printf '%-40s %s\n' 'NAME' 'VERSION'

for app in /Applications/*.app /Applications/Utilities/*.app "$HOME/Applications"/*.app; do
  [[ -d "$app" ]] || continue
  name=$(basename "$app" .app)
  if [[ -n "$filter" ]] && ! printf '%s' "$name" | grep -qi -- "$filter"; then
    continue
  fi
  version=$(defaults read "$app/Contents/Info" CFBundleShortVersionString 2>/dev/null || printf 'unknown')
  printf '%-40s %s\n' "$name" "$version"
done
