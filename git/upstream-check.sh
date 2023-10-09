#!/usr/bin/env bash
# Compare the current branch with its upstream.
# Usage: upstream-check.sh [-h]
# Needs: git

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

git rev-parse --git-dir >/dev/null 2>&1 || die "this is not a git repository."

BRANCH=$(git symbolic-ref --short -q HEAD 2>/dev/null) ||
  die "detached HEAD. Check out a branch first."
UP=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null) ||
  die "no upstream for $BRANCH. Run: git branch -u origin/$BRANCH"

AHEAD=$(git rev-list --count "$UP..HEAD" 2>/dev/null || printf 0)
BEHIND=$(git rev-list --count "HEAD..$UP" 2>/dev/null || printf 0)
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

printf '🔎 %s tracks %s\n\n' "$BRANCH" "$UP"
printf '  %-12s %s commit(s) to push\n' 'Ahead' "$AHEAD"
printf '  %-12s %s commit(s) to pull\n' 'Behind' "$BEHIND"
printf '  %-12s %s file(s)\n' 'Changed' "$DIRTY"

if [ "$AHEAD" -gt 0 ]; then
  printf '\n📤 Commits to push\n\n'
  git log --oneline "$UP..HEAD" | head -n 5 | sed 's/^/   /'
fi

if [ "$BEHIND" -gt 0 ]; then
  printf '\n📥 Commits to pull\n\n'
  git log --oneline "HEAD..$UP" | head -n 5 | sed 's/^/   /'
  if [ "$DIRTY" -gt 0 ]; then
    printf '\n⚠️  The worktree has changes. Commit or stash them before a pull.\n'
  fi
fi

if [ "$AHEAD" -eq 0 ] && [ "$BEHIND" -eq 0 ]; then
  printf '\n✅ The branch is level with its upstream.\n'
fi
