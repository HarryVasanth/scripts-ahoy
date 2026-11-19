#!/usr/bin/env bash
set -euo pipefail

# Checks for macOS software updates, or installs them.
# Usage: software-update [--install] [--dry-run] [-y|--yes] [-h]
# Needs: softwareupdate

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat << 'EOF'
software-update - check for updates, or install all of them.

Usage: software-update [--install] [--dry-run] [-y|--yes]

  --install    Install every available update. This needs sudo.
  --dry-run    Show what would happen and change nothing.
  -y, --yes    Skip the confirmation prompt.
  -h, --help   Show this help.

With no option the tool lists the updates only.
EOF
}

install=0
dry_run=0
yes=0
for arg in "$@"; do
  case "$arg" in
    --install) install=1 ;;
    --dry-run) dry_run=1 ;;
    -y | --yes) yes=1 ;;
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
if [[ $install -eq 0 ]]; then
  printf '🔎 Checking for updates...\n'
  softwareupdate -l
  exit 0
fi
if [[ $dry_run -eq 1 ]]; then
  printf '🧪 Dry run. No update will be installed.\n'
  softwareupdate -l
  printf '\nTo install: sudo softwareupdate -i -a\n'
  exit 0
fi

if [[ $yes -eq 0 ]]; then
  printf '⚠️  This installs all updates and may restart the Mac.\n'
  printf 'Continue? [y/N] '
  read -r reply
  case "$reply" in
    y | Y | yes | YES) ;;
    *)
      printf 'Cancelled.\n'
      exit 0
      ;;
  esac
fi

printf '🔐 sudo is needed to install the updates.\n'
sudo softwareupdate -i -a
