#!/usr/bin/env bash
# Summarise recent logins and failed attempts.
# Usage: login-history.sh [-n COUNT] [-h]
# Needs: last
# Note: Failed attempts need lastb or a readable auth log.

set -euo pipefail

TOP=10

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n) [ "$#" -ge 2 ] || die "-n needs a number."; TOP=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option $1" ;;
  esac
done

case "$TOP" in
  ''|*[!0-9]*|0) die "-n needs a number above zero." ;;
esac

command -v last >/dev/null 2>&1 || die "last is not installed."

printf '🔎 Recent successful logins\n\n'
last -n "$TOP" 2>/dev/null | sed 's/^/   /' || printf '   Not available.\n'

printf '\n👤 Logins by user\n\n'
last -n 100 2>/dev/null | awk '
  /^(reboot|shutdown|wtmp)/ { next }
  NF < 3 { next }
  { count[$1]++ }
  END { for (u in count) printf "%5d  %s\n", count[u], u }
' | sort -rn | head -n "$TOP" | sed 's/^/  /'

FAILED=
if command -v lastb >/dev/null 2>&1; then
  FAILED=$(lastb -n "$TOP" 2>/dev/null | grep -vE '^(btmp|$)' || true)
fi
if [ -z "$FAILED" ] && [ -r /var/log/auth.log ]; then
  FAILED=$(grep -iE 'Failed password|Invalid user' /var/log/auth.log 2>/dev/null | tail -n "$TOP" || true)
fi
if [ -z "$FAILED" ] && [ -r /var/log/secure ]; then
  FAILED=$(grep -iE 'Failed password|Invalid user' /var/log/secure 2>/dev/null | tail -n "$TOP" || true)
fi
if [ -z "$FAILED" ] && command -v journalctl >/dev/null 2>&1; then
  FAILED=$(journalctl -u ssh -u sshd --since '7 days ago' --no-pager -o cat 2>/dev/null |
    grep -iE 'Failed password|Invalid user' | tail -n "$TOP" || true)
fi

printf '\n🔎 Failed attempts\n\n'
if [ -z "$FAILED" ]; then
  printf '✅ No failed attempts found, or the log needs root.\n'
  printf '   Run as root to read lastb or the auth log.\n'
  exit 0
fi

COUNT=$(printf '%s\n' "$FAILED" | wc -l | tr -d ' ')
printf '⚠️  %s failed attempt line(s). The last %s follow.\n\n' "$COUNT" "$TOP"
printf '%s\n' "$FAILED" | tail -n "$TOP" | sed 's/^/   /'
