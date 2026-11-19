#!/usr/bin/env bash
# Prune stale remote-tracking branches.
# Usage: remote-prune.sh [-n] [REMOTE...]
# Needs: git

set -euo pipefail

DRY=0
REMOTES=()

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n | --dry-run)
      DRY=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "unknown option $1" ;;
    *)
      REMOTES+=("$1")
      shift
      ;;
  esac
done

git rev-parse --git-dir > /dev/null 2>&1 || die "this is not a git repository."

if [ "${#REMOTES[@]}" -eq 0 ]; then
  while IFS= read -r r; do
    REMOTES+=("$r")
  done < <(git remote)
fi
[ "${#REMOTES[@]}" -gt 0 ] || die "this repository has no remotes."

for r in "${REMOTES[@]}"; do
  git remote get-url "$r" > /dev/null 2>&1 || die "no such remote: $r"
  printf '🔎 %s\n\n' "$r"
  if [ "$DRY" -eq 1 ]; then
    OUT=$(git remote prune --dry-run "$r" 2>&1 || true)
  else
    OUT=$(git remote prune "$r" 2>&1 || true)
  fi
  if [ -z "$OUT" ]; then
    printf '   ✅ No stale branches.\n'
  else
    printf '%s\n' "$OUT" | sed 's/^/   /'
  fi
  COUNT=$(printf '%s\n' "$OUT" | grep -cE '\[(would prune|pruned)\]' || true)
  if [ "$DRY" -eq 1 ]; then
    printf '\n   ℹ️  %s branch(es) would be pruned. Run without -n to prune.\n' "${COUNT:-0}"
  else
    printf '\n   ✅ %s stale branch(es) pruned.\n' "${COUNT:-0}"
  fi
  printf '\n'
done
