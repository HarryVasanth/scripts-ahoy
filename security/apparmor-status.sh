#!/usr/bin/env bash
# Show AppArmor profiles and recent denials.
# Usage: apparmor-status.sh [-n COUNT] [-h]
# Needs: aa-status (Debian and Ubuntu)
# Note: Denials need root to read.

set -euo pipefail

TOP=10

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n)
      [ "$#" -ge 2 ] || die "-n needs a number."
      TOP=$2
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "unknown option $1" ;;
  esac
done

case "$TOP" in
  '' | *[!0-9]* | 0) die "-n needs a number above zero." ;;
esac

if [ "$(uname -s)" = Darwin ]; then
  printf 'ℹ️  AppArmor is not used on macOS. Try selinux-status.sh on Linux.\n'
  exit 0
fi

STATUS=
if command -v aa-status > /dev/null 2>&1; then
  STATUS=aa-status
elif command -v apparmor_status > /dev/null 2>&1; then
  STATUS=apparmor_status
else
  printf 'ℹ️  No AppArmor tools found. This host may use SELinux.\n' >&2
  printf '   Install apparmor-utils, then run again.\n' >&2
  exit 1
fi

printf '🔎 AppArmor profiles\n\n'
sudo -n "$STATUS" 2> /dev/null || "$STATUS" 2> /dev/null \
  || printf '   Needs root. Run: sudo %s\n' "$STATUS"

printf '\n🔎 Recent denials\n\n'
DENIALS=
if command -v journalctl > /dev/null 2>&1; then
  DENIALS=$(journalctl -k --since '24 hours ago' --no-pager 2> /dev/null | grep -i 'apparmor="DENIED"' || true)
fi
if [ -z "$DENIALS" ]; then
  DENIALS=$(dmesg 2> /dev/null | grep -i 'apparmor="DENIED"' || true)
fi

if [ -z "$DENIALS" ]; then
  printf '✅ No recent denials found, or the log needs root.\n'
  exit 0
fi

COUNT=$(printf '%s\n' "$DENIALS" | wc -l | tr -d ' ')
printf '⚠️  %s denial line(s). The last %s follow.\n\n' "$COUNT" "$TOP"
printf '%s\n' "$DENIALS" | tail -n "$TOP" | sed 's/^/   /'
printf '\nℹ️  Read the profile before you change it. A denial can be correct.\n'
