#!/usr/bin/env bash

# Remove old Proxmox kernels and keep the running one.
# Usage: ./clean-old-kernels.sh [--dry-run] [--force]
# Needs: dpkg-query, apt-get, update-grub (Proxmox VE only)
# Note: Run this on the Proxmox host, not inside a container.

set -euo pipefail

BOOT_CRITICAL_PERCENT="${BOOT_CRITICAL_PERCENT:-90}"
DRY_RUN=0
FORCE=0

usage() {
  cat << 'EOF'
Usage: clean-old-kernels.sh [--dry-run] [--force]

Remove old Proxmox kernels and keep the running one.

Options:
  --dry-run   Show what would be removed. Change nothing.
  --force     Do not ask for confirmation.
  -h, --help  Show this help.

Set BOOT_CRITICAL_PERCENT to change the /boot warning level. Default: 90.
EOF
}

die() {
  printf '[-] %s\n' "$*" >&2
  exit 1
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "Unknown option: $arg" ;;
  esac
done

[[ $(uname -s) == "Linux" ]] || die "This script only runs on Linux."
command -v dpkg-query > /dev/null 2>&1 || die "dpkg-query is missing. Is this a Debian system?"
command -v apt-get > /dev/null 2>&1 || die "apt-get is missing. Is this a Debian system?"

if ((EUID != 0)) && ((DRY_RUN == 0)); then
  die "Run this script as root, or add --dry-run."
fi

CURRENT_KERNEL=$(uname -r)
KERNELS=()
while IFS= read -r kernel; do
  [[ -n $kernel ]] && KERNELS+=("$kernel")
done < <(dpkg-query -W -f='${Package}\n' 'proxmox-kernel-*' 'pve-kernel-*' 2> /dev/null | sort -V || true)

if ((${#KERNELS[@]} == 0)); then
  printf '[!] No Proxmox kernel packages found. 😊\n'
  exit 0
fi

read -r boot_used boot_free < <(df -P /boot 2> /dev/null | awk 'NR == 2 { gsub("%", "", $5); print $5, $4 }')
boot_used=${boot_used:-0}
boot_free=${boot_free:-unknown}

if ((boot_used >= BOOT_CRITICAL_PERCENT)); then
  printf '[!] /boot is critically full at %s%% (%s free).\n' "$boot_used" "$boot_free"
else
  printf '[*] /boot is healthy at %s%% (%s free).\n' "$boot_used" "$boot_free"
fi

TO_REMOVE=()
for kernel in "${KERNELS[@]}"; do
  if [[ $kernel == *"$CURRENT_KERNEL"* ]]; then
    continue
  fi
  TO_REMOVE+=("$kernel")
  printf '[*] %s will be removed.\n' "$kernel"
done

if ((${#TO_REMOVE[@]} == 0)); then
  printf '[!] No old Proxmox kernels found. All clean. 😊\n'
  exit 0
fi

if ((DRY_RUN == 1)); then
  printf '[*] Dry run. Nothing was removed.\n'
  exit 0
fi

if ((FORCE == 0)); then
  printf '[!] Remove %d old kernel package(s)? [y/N] ' "${#TO_REMOVE[@]}"
  read -r reply
  [[ $reply =~ ^[Yy]$ ]] || {
    printf 'Exiting.\n'
    exit 0
  }
fi

printf '[*] Removing old kernels...\n'
apt-get purge -y "${TO_REMOVE[@]}" > /dev/null

if command -v update-grub > /dev/null 2>&1; then
  printf '[*] Updating GRUB...\n'
  update-grub > /dev/null
fi

printf '[✓] Cleanup finished successfully.\n'
