#!/usr/bin/env bash
# Renew the Proxmox VE node certificate through ACME.
# Usage: cert-renew [--dry-run] [-y]
# Needs: pvenode (Proxmox VE)
# Note: ACME must be configured already. Check with: pvenode acme account list

set -euo pipefail

dry_run=false
yes=false

usage() {
  cat <<'EOF'
Show the certificate status and renew it with ACME.

Options:
  --dry-run    Show the status and stop
  -y           Do not ask for confirmation
  -h, --help   Show this help
EOF
}

die() { printf '❌ %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=true; shift ;;
    -y) yes=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[ "$(id -u)" -eq 0 ] || die "Run this script as root."
command -v pvenode >/dev/null 2>&1 || die "pvenode is missing. This script must run on a Proxmox VE node."

printf '🔐 Current certificate status:\n'
if ! pvenode acme cert status; then
  die "Could not read the ACME status. Check the ACME configuration first."
fi

if [ "$dry_run" = true ]; then
  printf '\n🚧 Dry run. Would run: pvenode acme cert renew\n'
  exit 0
fi
if [ "$yes" = false ]; then
  printf '\nRenew the certificate now? [y/N] '
  read -r reply
  case "$reply" in
    [yY]|[yY][eE][sS]) ;;
    *) printf 'Cancelled. Nothing was changed.\n' >&2; exit 1 ;;
  esac
fi

printf '🔄 Renewing the certificate...\n'
pvenode acme cert renew
printf '✅ Renewal finished. Reload the web interface to see the new certificate.\n'
