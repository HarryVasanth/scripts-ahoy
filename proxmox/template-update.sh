#!/usr/bin/env bash
# Refresh LXC appliance templates in a Proxmox storage.
# Usage: template-update [-s STORAGE] [--all] [--dry-run] [-y] [TEMPLATE...]
# Needs: pveam (Proxmox VE)
# Note: A template with the same file name is downloaded again and replaced.

set -euo pipefail
storage=local
all=false
dry_run=false
yes=false

usage() {
  cat << 'EOF'
Download fresh appliance templates into a Proxmox storage.
Without names, the script lists the installed templates.
  -s STORAGE   Target storage (default: local)
  --all        Refresh every template the mirror offers
  --dry-run    Show the downloads and stop
  -y           Do not ask for confirmation
  -h, --help   Show this help
EOF
}

die() {
  printf '❌ %s\n' "$*" >&2
  exit 1
}
while [ $# -gt 0 ]; do
  case "$1" in
    -s)
      storage=${2:-}
      shift 2 || die "Option -s needs a value."
      ;;
    --all)
      all=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -y)
      yes=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
done

[ "$(id -u)" -eq 0 ] || die "Run this script as root."
command -v pveam > /dev/null 2>&1 || die "pveam is missing. This script must run on a Proxmox VE node."
pveam list "$storage" > /dev/null 2>&1 || die "Storage '$storage' is not ready, or it does not hold templates."
if [ "$all" = false ] && [ "$#" -eq 0 ]; then
  printf '📦 Templates in %s:\n' "$storage"
  pveam list "$storage" || true
  printf '\nName a template, or use --all to refresh every available one.\n'
  exit 0
fi
printf '🔄 Refreshing the template list from the mirror...\n' >&2
pveam update > /dev/null || die "Could not refresh the template list. Check the network."
templates=()
if [ "$all" = true ]; then
  while read -r name; do
    [ -n "$name" ] && templates+=("$name")
  done < <(pveam available --section system | awk 'NF > 1 {print $2}')
else
  templates=("$@")
fi
[ "${#templates[@]}" -gt 0 ] || die "The mirror offered no templates."

if [ "$dry_run" = true ]; then
  for name in "${templates[@]}"; do
    printf '🚧 Would download %s to %s\n' "${name##*/}" "$storage"
  done
  exit 0
fi
if [ "$yes" = false ]; then
  printf 'Download %s templates into %s? [y/N] ' "${#templates[@]}" "$storage"
  read -r reply
  case "$reply" in [yY] | [yY][eE][sS]) ;; *) die "Cancelled. Nothing was changed." ;; esac
fi
for name in "${templates[@]}"; do
  name=${name##*/}
  case "$name" in
    *.tar.gz | *.tar.xz | *.tar.zst) ;;
    *)
      printf '⏭️  Skip %s: not a template archive name.\n' "$name" >&2
      continue
      ;;
  esac
  printf '📥 %s -> %s\n' "$name" "$storage" >&2
  pveam download "$storage" "$name"
done
printf '✅ Template refresh finished.\n' >&2
