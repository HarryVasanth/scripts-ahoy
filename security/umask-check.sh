#!/usr/bin/env bash
# Show the current and configured umask.
# Usage: umask-check.sh [-h]

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

CURRENT=$(umask)
VALUE=$((8#$CURRENT))

printf '🔎 Current umask\n\n'
printf '  %-12s %s\n' 'Mask' "$CURRENT"
printf '  %-12s %s\n' 'Allowed' "$(umask -S 2>/dev/null || printf 'unknown')"

if [ $(( (~VALUE) & 8#2 )) -ne 0 ]; then
  printf '\n⚠️  Other users can write new files.\n'
fi

FILES=(/etc/profile /etc/bashrc /etc/bash.bashrc /etc/login.defs /etc/profile.d/*.sh
  "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshrc" "$HOME/.zprofile")

FOUND=0
printf '\n🔎 Configured settings\n\n'
for f in "${FILES[@]}"; do
  [ -f "$f" ] || continue
  while IFS= read -r line; do
    printf '  %s:%s\n' "$f" "$line"
    FOUND=1
  done < <(grep -nE '^[[:space:]]*[Uu][Mm][Aa][Ss][Kk][[:space:]=]+[0-7]{3,4}' "$f" 2>/dev/null || true)
done

if [ "$FOUND" -eq 0 ]; then
  printf '  No umask setting found in the common files.\n'
else
  printf '\nℹ️  The shell uses the last setting it reads. Login and non-login shells can differ.\n'
fi
