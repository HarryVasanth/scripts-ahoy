#!/usr/bin/env bash
# Show the auditd status and rule count.
# Usage: auditd-status.sh [-h]
# Needs: auditctl (Linux)
# Note: Some fields need root.

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
  printf 'ℹ️  auditd is a Linux service. macOS uses the unified log instead.\n'
  exit 0
fi

command -v auditctl > /dev/null 2>&1 \
  || die "auditctl is not installed. Install the audit package."

printf '🔎 auditd service\n\n'
if command -v systemctl > /dev/null 2>&1; then
  printf '  %-12s %s\n' 'Service' "$(systemctl is-active auditd 2> /dev/null || printf 'unknown')"
fi
printf '  %-12s %s\n' 'Tool' "$(command -v auditctl)"

printf '\n🔎 Status\n\n'
if ! auditctl -s 2> /dev/null | sed 's/^/   /'; then
  sudo -n auditctl -s 2> /dev/null | sed 's/^/   /' \
    || printf '   Cannot read the status. Run as root.\n'
fi

RULES=$(sudo -n auditctl -l 2> /dev/null | grep -cE '^[[:space:]]*-' || true)
if [ "${RULES:-0}" -eq 0 ]; then
  RULES=$(auditctl -l 2> /dev/null | grep -cE '^[[:space:]]*-' || true)
fi

printf '\n  %-12s %s\n' 'Rules' "${RULES:-0}"
if [ "${RULES:-0}" -eq 0 ]; then
  printf '\n⚠️  No audit rules are loaded. Add rules in /etc/audit/rules.d/.\n'
else
  printf '\nℹ️  Rules are loaded. Check /etc/audit/rules.d/ for the saved copy.\n'
fi
