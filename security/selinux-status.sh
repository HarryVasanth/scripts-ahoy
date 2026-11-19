#!/usr/bin/env bash
# Show the SELinux mode and recent denials.
# Usage: selinux-status.sh [-n COUNT] [-h]
# Needs: sestatus or getenforce (RHEL family)
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
  printf 'ℹ️  SELinux is not used on macOS. Try apparmor-status.sh on Linux.\n'
  exit 0
fi

if ! command -v getenforce > /dev/null 2>&1 && ! command -v sestatus > /dev/null 2>&1; then
  printf 'ℹ️  No SELinux tools found. This host may use AppArmor.\n' >&2
  printf '   Install policycoreutils, then run again.\n' >&2
  exit 1
fi

MODE=$(getenforce 2> /dev/null || printf 'unknown')
printf '🔎 SELinux mode: %s\n\n' "$MODE"

if command -v sestatus > /dev/null 2>&1; then
  sestatus 2> /dev/null | sed 's/^/   /' || true
fi

printf '\n🔎 Recent denials\n\n'
DENIALS=
if command -v ausearch > /dev/null 2>&1; then
  DENIALS=$(sudo -n ausearch -m AVC,USER_AVC -ts recent 2> /dev/null | grep 'type=' || true)
fi
if [ -z "$DENIALS" ] && command -v journalctl > /dev/null 2>&1; then
  DENIALS=$(journalctl -k --since '24 hours ago' --no-pager 2> /dev/null | grep -i 'avc: *denied' || true)
fi
if [ -z "$DENIALS" ] && [ -r /var/log/audit/audit.log ]; then
  DENIALS=$(grep 'avc: *denied' /var/log/audit/audit.log 2> /dev/null | tail -n "$TOP" || true)
fi

if [ -z "$DENIALS" ]; then
  printf '✅ No recent denials found, or the log needs root.\n'
  exit 0
fi

COUNT=$(printf '%s\n' "$DENIALS" | wc -l | tr -d ' ')
printf '⚠️  %s denial line(s). The last %s follow.\n\n' "$COUNT" "$TOP"
printf '%s\n' "$DENIALS" | tail -n "$TOP" | sed 's/^/   /'
printf '\nℹ️  Use audit2why to explain a denial. Change policy only after a review.\n'
