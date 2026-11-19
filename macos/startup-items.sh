#!/usr/bin/env bash
set -euo pipefail

# Lists login items and launch agents.
# Usage: startup-items [-h]
# Needs: osascript, defaults

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat << 'EOF'
startup-items - list login items and launch agents.

Usage: startup-items

The tool asks System Events for the login items. macOS may ask for permission
the first time. It then reads the agent plists in the user and system folders.
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

printf '🚀 Login items\n'
if ! items=$(osascript -e 'tell application "System Events" to get the name of every login item' 2> /dev/null); then
  printf '  (cannot read login items. Allow your terminal in System Settings > Privacy.)\n'
elif [[ -z "$items" ]]; then
  printf '  (none)\n'
else
  printf '%s\n' "$items" | tr ',' '\n' | sed 's/^ */  /'
fi

for dir in "$HOME/Library/LaunchAgents" /Library/LaunchAgents; do
  [[ -d "$dir" ]] || continue
  printf '\n📂 %s\n' "$dir"
  found=0
  for plist in "$dir"/*.plist; do
    [[ -e "$plist" ]] || continue
    found=1
    label=$(defaults read "$plist" Label 2> /dev/null || basename "$plist" .plist)
    printf '  %s\n' "$label"
  done
  [[ $found -eq 1 ]] || printf '  (none)\n'
done
