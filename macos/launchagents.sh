#!/usr/bin/env bash
set -euo pipefail

# Lists user launch agents and their state.
# Usage: launchagents [-h]
# Needs: launchctl, defaults

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat << 'EOF'
launchagents - list user launch agents and their state.

Usage: launchagents

The tool reads ~/Library/LaunchAgents and asks launchctl which agents are
loaded or running. A loaded agent with no process is idle.
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

dir="$HOME/Library/LaunchAgents"
if [[ ! -d "$dir" ]]; then
  printf 'No user launch agents folder at %s\n' "$dir"
  exit 0
fi

tmp=$(mktemp) || exit 1
trap 'rm -f "$tmp"' EXIT
launchctl list > "$tmp" 2> /dev/null || true

printf '⚙️  User launch agents\n'
found=0
for plist in "$dir"/*.plist; do
  [[ -e "$plist" ]] || continue
  found=1
  label=$(defaults read "$plist" Label 2> /dev/null || basename "$plist" .plist)
  state=$(awk -v l="$label" '$3 == l {print ($1 == "-" ? "loaded, not running" : "running, pid " $1)}' "$tmp")
  [[ -n "$state" ]] || state="not loaded"
  printf '  %-42s %s\n' "$label" "$state"
done
if [[ $found -eq 0 ]]; then
  printf '  (none)\n'
fi
