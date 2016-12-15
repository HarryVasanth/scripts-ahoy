#!/usr/bin/env bash
# Install git hooks from .githooks into the repository.
# Usage: hooks-install.sh [-f] [-h]
# Needs: git
# Note: -f replaces an existing hook after making a backup copy.

set -euo pipefail

FORCE=0

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -f|--force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option $1" ;;
  esac
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "this is not a git repository."
ROOT=$(git rev-parse --show-toplevel)
SRC="$ROOT/.githooks"
[ -d "$SRC" ] || die "no .githooks folder in $ROOT"

HOOKS=$(git -C "$ROOT" rev-parse --git-path hooks)
case "$HOOKS" in
  /*) ;;
  *) HOOKS="$ROOT/$HOOKS" ;;
esac
mkdir -p "$HOOKS"

HOOK_PATH=$(git -C "$ROOT" config --get core.hooksPath 2>/dev/null || true)
if [ -n "$HOOK_PATH" ]; then
  printf '⚠️  core.hooksPath is %s. Git may ignore %s.\n' "$HOOK_PATH" "$HOOKS" >&2
fi

INSTALLED=0
for src in "$SRC"/*; do
  [ -f "$src" ] || continue
  name=$(basename "$src")
  case "$name" in
    *.sample) continue ;;
  esac
  dest="$HOOKS/$name"
  if [ -f "$dest" ]; then
    if cmp -s "$src" "$dest"; then
      printf 'ℹ️  %s is already current.\n' "$name"
      continue
    fi
    if [ "$FORCE" -eq 0 ]; then
      printf '⚠️  %s exists. Use -f to replace it.\n' "$name" >&2
      continue
    fi
    backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$backup"
    printf 'ℹ️  Backed up %s to %s.\n' "$name" "$backup"
  fi
  cp "$src" "$dest"
  chmod +x "$dest"
  printf '✅ Installed %s\n' "$name"
  INSTALLED=$((INSTALLED + 1))
done

if [ "$INSTALLED" -eq 0 ]; then
  printf 'ℹ️  Nothing new to install.\n'
fi
exit 0
