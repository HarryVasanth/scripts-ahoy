#!/usr/bin/env bash
set -euo pipefail

# Empties the Trash after a confirmation.
# Usage: trash-empty [--dry-run] [-y|--yes] [-h]
# Needs: osascript, Finder

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
trash-empty - empty the Trash.

Usage: trash-empty [--dry-run] [-y|--yes]

  --dry-run   Show the item count and size, then stop.
  -y, --yes   Skip the confirmation prompt.
  -h, --help  Show this help.

The tool asks Finder to empty the Trash. This cannot be undone.
EOF
}

dry_run=0
yes=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=1 ;;
    -y | --yes) yes=1 ;;
    -h | --help) show_help; exit 0 ;;
    *)
      printf 'Error: unknown argument: %s\n' "$arg" >&2
      show_help >&2
      exit 1
      ;;
  esac
done
trash="$HOME/.Trash"
if [[ ! -d "$trash" ]]; then
  printf 'The Trash is already empty.\n'
  exit 0
fi

count=$(find "$trash" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ' || true)
size=$(du -sh "$trash" 2>/dev/null | awk '{print $1}' || true)
printf '🗑️  Trash: %s items, %s\n' "$count" "${size:-unknown}"
if [[ $dry_run -eq 1 ]]; then
  printf '🧪 Dry run. Nothing was deleted.\n'
  exit 0
fi
if [[ $count -eq 0 ]]; then
  printf 'The Trash is already empty.\n'
  exit 0
fi

if [[ $yes -eq 0 ]]; then
  printf 'Delete all items in the Trash? This cannot be undone. [y/N] '
  read -r reply
  case "$reply" in
    y | Y | yes | YES) ;;
    *) printf 'Cancelled.\n'; exit 0 ;;
  esac
fi

printf '🧹 Emptying the Trash...\n'
osascript -e 'tell application "Finder" to empty trash' >/dev/null
printf '✅ The Trash is empty.\n'
