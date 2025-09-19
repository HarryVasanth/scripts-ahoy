#!/usr/bin/env bash
# Audit sudoers rules for risky settings.
# Usage: sudoers-audit.sh [-d DIR] [-h]
# Note: Reports only. Run it with sudo to read all files.

set -euo pipefail

DIR=
FOUND=0
FILES=()

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -d) [ "$#" -ge 2 ] || die "-d needs a path."; DIR=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option $1" ;;
  esac
done

if [ -n "$DIR" ]; then
  [ -d "$DIR" ] || die "no such folder: $DIR"
  for f in "$DIR"/*; do
    [ -f "$f" ] && FILES+=("$f")
  done
else
  [ -f /etc/sudoers ] && FILES+=(/etc/sudoers)
  for f in /etc/sudoers.d/*; do
    [ -f "$f" ] && FILES+=("$f")
  done
fi
[ "${#FILES[@]}" -gt 0 ] || die "no sudoers files found."

READABLE=0
for f in "${FILES[@]}"; do
  if [ -r "$f" ]; then
    READABLE=$((READABLE + 1))
  else
    printf '⚠️  Cannot read %s. Try sudo.\n' "$f" >&2
  fi
done
[ "$READABLE" -gt 0 ] || die "no readable sudoers files. Try: sudo $0"

if [ -z "$DIR" ] && [ -r /etc/sudoers ] && command -v visudo >/dev/null 2>&1; then
  if visudo -c >/dev/null 2>&1; then
    printf '✅ visudo reports no syntax errors.\n'
  else
    printf '❌ visudo reports a syntax error. Check the files below.\n'
  fi
  printf '\n'
fi

scan() {
  local pattern=$1 label=$2 hits
  hits=$(grep -HnE "$pattern" "${FILES[@]}" 2>/dev/null | grep -vE ':[0-9]+:[[:space:]]*#' || true)
  [ -n "$hits" ] || return 0
  printf '⚠️  %s\n' "$label"
  printf '%s\n' "$hits" | sed 's/^/   /'
  FOUND=$((FOUND + $(printf '%s\n' "$hits" | wc -l | tr -d ' ')))
}

scan 'NOPASSWD' 'Password-free sudo rule'
scan '!authenticate' 'Authentication bypass'
scan 'ALL[[:space:]]*=[[:space:]]*\(ALL(:ALL)?\)[[:space:]]+ALL' 'Broad rule for any user and any command'

printf '\n🔎 Checked %s file(s). Found %s risky line(s).\n' "${#FILES[@]}" "$FOUND"
