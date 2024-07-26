#!/usr/bin/env bash
# Check the PAM password quality policy.
# Usage: password-policy.sh [-h]
# Note: This script only reads files. It changes nothing.

set -euo pipefail

shopt -s nullglob

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    *) die "unknown option $1" ;;
  esac
done

if [ "$(uname -s)" = Darwin ]; then
  printf 'ℹ️  macOS sets password rules with pwpolicy.\n'
  printf '   Run for details: pwpolicy -getaccountpolicies\n\n'
fi

PAM_FILES=(/etc/pam.d/common-password /etc/pam.d/system-auth /etc/pam.d/password-auth
  /etc/pam.d/passwd)
FOUND=0

for f in "${PAM_FILES[@]}"; do
  [ -f "$f" ] || continue
  FOUND=1
  printf '🔎 %s\n\n' "$f"
  grep -vE '^[[:space:]]*(#|$)' "$f" 2>/dev/null | sed 's/^/   /' || true
  printf '\n'
done

if [ "$FOUND" -eq 0 ]; then
  printf '⚠️  No PAM password file found.\n'
fi

printf '🔎 pwquality settings\n\n'
SHOWN=0
for key in minlen dcredit ucredit lcredit ocredit minclass maxrepeat maxclassrepeat difok retry enforce_for_root; do
  val=$(grep -hE "^[[:space:]]*${key}[[:space:]]*=" /etc/security/pwquality.conf 2>/dev/null |
    tail -n 1 | sed 's/.*=[[:space:]]*//')
  if [ -n "$val" ]; then
    printf '  %-16s %s\n' "$key" "$val"
    SHOWN=1
  fi
done
if [ "$SHOWN" -eq 0 ]; then
  printf '  No settings in /etc/security/pwquality.conf.\n'
fi

printf '\n🔎 Password ageing (/etc/login.defs)\n\n'
grep -E '^[[:space:]]*(PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_MIN_LEN|PASS_WARN_AGE)' \
  /etc/login.defs 2>/dev/null | sed 's/^/   /' || printf '   Not found.\n'

printf '\nℹ️  A missing setting uses the module default. Check the PAM line for the active module.\n'
