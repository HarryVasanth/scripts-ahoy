#!/usr/bin/env bash
# Summarise failed login attempts from system logs.
# Usage: failed-logins.sh [-f LOGFILE] [-n COUNT] [-h]
# Note: macOS reads the unified log and can take a minute.

set -euo pipefail

FILE=
TOP=10
PATTERN='Failed password|Invalid user|Failed publickey|authentication failure|FAILED su|FAILED login'

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -f)
      [ "$#" -ge 2 ] || die "-f needs a path."
      FILE=$2
      shift 2
      ;;
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

TMP=$(mktemp "${TMPDIR:-/tmp}/failed-logins.XXXXXX")
trap 'rm -f "$TMP"' EXIT

if [ -n "$FILE" ]; then
  [ -r "$FILE" ] || die "cannot read $FILE"
  cp "$FILE" "$TMP"
elif [ -r /var/log/auth.log ]; then
  cp /var/log/auth.log "$TMP"
elif [ -r /var/log/secure ]; then
  cp /var/log/secure "$TMP"
elif command -v journalctl > /dev/null 2>&1; then
  journalctl -u ssh -u sshd --since '7 days ago' --no-pager -o cat 2> /dev/null > "$TMP" || true
elif [ "$(uname -s)" = Darwin ]; then
  printf 'ℹ️  Reading the macOS unified log. This can take a minute.\n' >&2
  log show --last 1d --style compact --predicate 'process == "sshd" OR process == "sudo"' 2> /dev/null > "$TMP" || true
else
  die "no readable login log. Use -f LOGFILE."
fi

TOTAL=$(grep -icE "$PATTERN" "$TMP" || true)
if [ "${TOTAL:-0}" -eq 0 ]; then
  printf '✅ No failed logins found in the log.\n'
  exit 0
fi

printf '🔎 %s failed login line(s) found.\n\n' "$TOTAL"
printf 'Top source addresses\n'
grep -iE "$PATTERN" "$TMP" \
  | grep -oE '(from|rhost=) ?[^ ]+' \
  | sed 's/^from //; s/^rhost=//' \
  | sort | uniq -c | sort -rn | head -n "$TOP" \
  | awk '{ printf "  %5d  %s\n", $1, $2 }' || true

LAST=$(grep -iE "$PATTERN" "$TMP" | tail -n 1 || true)
printf '\nLast matching line\n   %s\n' "$LAST"
