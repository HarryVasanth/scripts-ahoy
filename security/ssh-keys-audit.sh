#!/usr/bin/env bash
# Audit SSH authorised keys files for permissions and options.
# Usage: ssh-keys-audit.sh [-h]
# Needs: stat, awk

set -euo pipefail

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

if stat -c '%a' "$0" >/dev/null 2>&1; then
  mode_of() { stat -c '%a' "$1" 2>/dev/null; }
  owner_of() { stat -c '%U' "$1" 2>/dev/null; }
else
  mode_of() { stat -f '%Lp' "$1" 2>/dev/null; }
  owner_of() { stat -f '%Su' "$1" 2>/dev/null; }
fi

DIRS=("$HOME/.ssh" /root/.ssh)
for d in /home/*/.ssh /Users/*/.ssh; do
  DIRS+=("$d")
done

FILES=0
ISSUES=0
for d in "${DIRS[@]}"; do
  [ -d "$d" ] || continue
  dmode=$(mode_of "$d")
  dtail=${dmode: -3}
  if [ $(( 8#${dtail:1:1} & 2 )) -ne 0 ] || [ $(( 8#${dtail:2:1} & 2 )) -ne 0 ]; then
    printf '⚠️  Folder is group or world writable: %s (%s)\n' "$d" "$dmode"
    ISSUES=$((ISSUES + 1))
  fi
  for f in "$d"/authorized_keys "$d"/authorized_keys2; do
    [ -f "$f" ] || continue
    FILES=$((FILES + 1))
    mode=$(mode_of "$f")
    owner=$(owner_of "$f")
    tail3=${mode: -3}
    if [ $(( 8#${tail3:1:1} & 2 )) -ne 0 ] || [ $(( 8#${tail3:2:1} & 2 )) -ne 0 ]; then
      printf '⚠️  Bad mode: %s (%s, owner %s)\n' "$f" "$mode" "$owner"
      ISSUES=$((ISSUES + 1))
    else
      printf '✅ %s: mode %s, owner %s\n' "$f" "$mode" "$owner"
    fi
    awk '
      /^[[:space:]]*(#|$)/ { next }
      {
        total++
        if ($1 !~ /^(ssh-|ecdsa-|sk-|cert-)/ && $1 ~ /(from=|command=|restrict|no-pty)/) restricted++
        else bare++
      }
      END {
        if (total == 0) print "   No keys in this file."
        else printf "   %d key(s): %d with restrictions, %d without.\n", total, restricted, bare
      }
    ' "$f"
  done
done
printf '\n🔎 %s authorised keys file(s) checked, %s permission issue(s).\n' "$FILES" "$ISSUES"
