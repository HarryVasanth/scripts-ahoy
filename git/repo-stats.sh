#!/usr/bin/env bash
# Show a quick summary of the current repository.
# Usage: repo-stats.sh [-h]
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

command -v git >/dev/null 2>&1 || die "git is not installed."
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "this is not a git repository."

ROOT=$(git rev-parse --show-toplevel 2>/dev/null || printf '.')
BRANCH=$(git symbolic-ref --short -q HEAD 2>/dev/null || printf 'detached HEAD')
COMMITS=$(git rev-list --count HEAD 2>/dev/null || printf 0)
FILES=$(git ls-files 2>/dev/null | wc -l | tr -d ' ')
AUTHORS=$(git shortlog -sn --all 2>/dev/null | wc -l | tr -d ' ')
TAGS=$(git tag 2>/dev/null | wc -l | tr -d ' ')
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
LAST=$(git log -1 --format='%cs' 2>/dev/null || true)
FIRST=$(git log --format='%cs' 2>/dev/null | tail -n 1 || true)
SIZE=$(du -sh "$(git rev-parse --git-dir)" 2>/dev/null | cut -f1 || true)

printf '📊 %s\n\n' "$ROOT"
printf '  %-16s %s\n' 'Branch' "${BRANCH:-detached HEAD}"
printf '  %-16s %s\n' 'Commits' "${COMMITS:-0}"
printf '  %-16s %s\n' 'Contributors' "${AUTHORS:-0}"
printf '  %-16s %s\n' 'Tracked files' "${FILES:-0}"
printf '  %-16s %s\n' 'Tags' "${TAGS:-0}"
printf '  %-16s %s\n' 'Changed files' "${DIRTY:-0}"
printf '  %-16s %s\n' 'First commit' "${FIRST:-none}"
printf '  %-16s %s\n' 'Last commit' "${LAST:-none}"
printf '  %-16s %s\n' 'Repository size' "${SIZE:-unknown}"

if [ "${DIRTY:-0}" -gt 0 ]; then
  printf '\nℹ️  The worktree has uncommitted changes.\n'
fi
