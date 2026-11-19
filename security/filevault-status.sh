#!/usr/bin/env bash
# Report full-disk encryption status.
# Usage: filevault-status.sh [-h]
# Note: On Linux it lists LUKS containers. It cannot show if they are unlocked.

set -euo pipefail

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    *) die "unknown option $1" ;;
  esac
done

if [ "$(uname -s)" = Darwin ]; then
  command -v fdesetup > /dev/null 2>&1 || die "fdesetup is missing."
  printf '🔎 FileVault\n'
  if fdesetup status 2> /dev/null | grep -q 'FileVault is On'; then
    printf '✅ FileVault is on.\n'
  else
    printf '⚠️  FileVault is off or deferred.\n'
    fdesetup status 2> /dev/null || true
  fi
  exit 0
fi

command -v lsblk > /dev/null 2>&1 || die "lsblk is missing. Try: sudo apt install util-linux"

printf '🔎 LUKS containers\n'
LUKS=$(lsblk -o NAME,TYPE,FSTYPE,SIZE,MOUNTPOINT 2> /dev/null \
  | awk 'NR == 1 || $3 == "crypto_LUKS" || $2 == "crypt"' || true)
if [ -n "$LUKS" ]; then
  printf '%s\n' "$LUKS"
  printf '\nℹ️  Use sudo cryptsetup status NAME to see the state of a container.\n'
else
  printf '⚠️  No LUKS containers found.\n'
fi
