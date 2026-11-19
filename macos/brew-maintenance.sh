#!/usr/bin/env bash
set -euo pipefail
# Updates Homebrew and removes old files.
# Usage: brew-maintenance [--dry-run] [-y|--yes] [--no-upgrade] [-h]
if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi
if ! command -v brew > /dev/null 2>&1; then
  printf 'Error: brew is missing. Install it from https://brew.sh\n' >&2
  exit 1
fi
show_help() {
  cat << 'EOF'
brew-maintenance - update Homebrew and clean old files.

Usage: brew-maintenance [--dry-run] [--yes] [--no-upgrade]

  --dry-run     Show what is outdated. Change nothing.
  -y, --yes     Do not ask for confirmation.
  --no-upgrade  Skip the upgrade. Clean only.
  -h, --help    Show this help.
EOF
}
dry_run=0
assume_yes=0
do_upgrade=1
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=1 ;;
    -y | --yes) assume_yes=1 ;;
    --no-upgrade) do_upgrade=0 ;;
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
if [[ $dry_run -eq 1 ]]; then
  printf '🔍 Dry run. Nothing will change.\n\nOutdated packages:\n'
  brew outdated || true
  printf '\nFiles that cleanup would remove:\n'
  brew cleanup --dry-run || true
  exit 0
fi
if [[ $assume_yes -eq 0 ]]; then
  printf 'Update Homebrew, upgrade packages and clean old files? [y/N] '
  read -r answer || answer=""
  case "$answer" in
    [yY]*) ;;
    *)
      printf 'Nothing changed.\n'
      exit 0
      ;;
  esac
fi
printf '\n⬆️  Updating Homebrew...\n'
brew update
if [[ $do_upgrade -eq 1 ]]; then
  printf '\n⬆️  Upgrading packages...\n'
  brew upgrade || printf '⚠️  Some packages did not upgrade.\n'
fi
printf '\n🧹 Removing old files...\n'
brew cleanup --prune=all
printf '\n🩺 Running the doctor...\n'
brew doctor || true
printf '\n✅ Done.\n'
