#!/usr/bin/env bash
set -euo pipefail

# Removes unused packages and cached files from an apt system.
# Usage: apt-cleanup [--dry-run] [-y|--yes] [-h]
# Needs: apt-get (Debian, Ubuntu)
# Note: this tool needs root. Run it as: sudo apt-cleanup

show_help() {
  cat << 'EOF'
apt-cleanup - clean the apt package cache.

Usage: apt-cleanup [--dry-run] [--yes]

  --dry-run   Show what would be removed. Change nothing.
  -y, --yes   Do not ask for confirmation.
  -h, --help  Show this help.

The tool removes unused dependencies, old package files and the download cache.
EOF
}

dry_run=0
assume_yes=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=1 ;;
    -y | --yes) assume_yes=1 ;;
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

if ! command -v apt-get > /dev/null 2>&1; then
  printf 'Error: apt-get is missing. This tool needs Debian or Ubuntu.\n' >&2
  exit 1
fi

if [[ $dry_run -eq 1 ]]; then
  printf '🔍 Dry run. Nothing will change.\n\n'
  printf 'Packages that autoremove would delete:\n'
  apt-get -s autoremove --purge | awk '/^Remv/ {print "  " $0}' || true
  printf '\nDownload cache size: %s\n' "$(du -sh /var/cache/apt/archives 2> /dev/null | cut -f1)"
  exit 0
fi

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  printf 'Error: this tool needs root. Run it with sudo.\n' >&2
  exit 1
fi

if [[ $assume_yes -eq 0 ]]; then
  printf 'Remove unused packages and cached files? [y/N] '
  read -r answer || answer=""
  case "$answer" in
    [yY]*) ;;
    *)
      printf 'Nothing changed.\n'
      exit 0
      ;;
  esac
fi

printf '\n🧹 Removing unused packages...\n'
apt-get autoremove --purge -y

printf '\n🧹 Removing old package files...\n'
apt-get autoclean -y

printf '\n🧹 Clearing the download cache...\n'
apt-get clean

printf '\n✅ Done.\n'
