#!/usr/bin/env bash
set -euo pipefail

# Resets the macOS Dock to its default layout.
# Usage: dock-reset [--dry-run] [-y|--yes] [-h]
# Note: this removes every Dock customisation, including added apps.

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
dock-reset - reset the Dock to the default layout.

Usage: dock-reset [--dry-run] [--yes]

  --dry-run   Show what would happen. Change nothing.
  -y, --yes   Do not ask for confirmation.
  -h, --help  Show this help.

The tool deletes the Dock preferences and restarts the Dock. Pinned apps,
size and position return to the defaults.
EOF
}

dry_run=0
assume_yes=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=1 ;;
    -y | --yes) assume_yes=1 ;;
    -h | --help) show_help; exit 0 ;;
    *)
      printf 'Error: unknown argument: %s\n' "$arg" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

printf '⚠️  This removes all Dock customisation.\n'

if [[ $dry_run -eq 1 ]]; then
  printf '\n🔍 Dry run. These steps would run:\n'
  printf '  defaults delete com.apple.dock\n'
  printf '  killall Dock\n'
  exit 0
fi

if [[ $assume_yes -eq 0 ]]; then
  printf 'Continue? [y/N] '
  read -r answer || answer=""
  case "$answer" in
    [yY]*) ;;
    *)
      printf 'Nothing changed.\n'
      exit 0
      ;;
  esac
fi

defaults delete com.apple.dock 2>/dev/null || printf 'No Dock preferences to delete.\n'
killall Dock

printf '✅ The Dock is back to its default layout.\n'
