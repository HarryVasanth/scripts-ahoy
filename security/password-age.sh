#!/usr/bin/env bash
# Report local accounts with old or missing passwords.
# Usage: password-age.sh [-f SHADOW] [-d DAYS] [-h]
# Note: Reads shadow format only. Run with sudo to read /etc/shadow on Linux.

set -euo pipefail

SHADOW=/etc/shadow
DAYS=90
COUNT=0
OLD=0
NOPASS=0

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -f) [ "$#" -ge 2 ] || die "-f needs a path."; SHADOW=$2; shift 2 ;;
    -d) [ "$#" -ge 2 ] || die "-d needs a number."; DAYS=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option $1" ;;
  esac
done

case "$DAYS" in
  ''|*[!0-9]*|0) die "-d needs a number above zero." ;;
esac

if [ ! -r "$SHADOW" ]; then
  if [ "$SHADOW" = /etc/shadow ] && [ "$(uname -s)" = Darwin ]; then
    printf 'ℹ️  macOS keeps password data in a protected store.\n' >&2
    printf '   Use System Settings, or check a policy with: pwpolicy -u USER -getpolicy\n' >&2
    exit 0
  fi
  die "cannot read $SHADOW. Try: sudo $0"
fi

TODAY=$(( $(date +%s) / 86400 ))
printf '🔎 Accounts with passwords older than %s days\n\n' "$DAYS"

while IFS=: read -r user hash last _; do
  if [ -z "$hash" ]; then
    printf '❌ %s has no password set.\n' "$user"
    NOPASS=$((NOPASS + 1))
    continue
  fi
  case "$hash" in
    '*'|'!'*|'*LK*') continue ;;
  esac
  case "$last" in
    ''|*[!0-9]*) continue ;;
  esac
  [ "$last" -gt 0 ] || continue
  COUNT=$((COUNT + 1))
  age=$((TODAY - last))
  if [ "$age" -gt "$DAYS" ]; then
    printf '⚠️  %s: the password is %s days old.\n' "$user" "$age"
    OLD=$((OLD + 1))
  fi
done < "$SHADOW"

printf '\n%s account(s) checked. %s old. %s without a password.\n' "$COUNT" "$OLD" "$NOPASS"
