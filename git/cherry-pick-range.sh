#!/usr/bin/env bash
# Cherry-pick a commit range onto a branch.
# Usage: cherry-pick-range.sh [-b BRANCH] [-n] RANGE
# Needs: git
# Note: This script never pushes.

set -euo pipefail

BRANCH=
NOCOMMIT=0
RANGE=

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -b)
      [ "$#" -ge 2 ] || die "-b needs a branch."
      BRANCH=$2
      shift 2
      ;;
    -n | --no-commit)
      NOCOMMIT=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "unknown option $1" ;;
    *)
      [ -z "$RANGE" ] || die "give one range only."
      RANGE=$1
      shift
      ;;
  esac
done

[ -n "$RANGE" ] || die "give a range, for example main~3..main. See --help."
git rev-parse --git-dir > /dev/null 2>&1 || die "this is not a git repository."
COUNT=$(git rev-list --count "$RANGE" 2> /dev/null) || die "bad range: $RANGE"
[ "$COUNT" -gt 0 ] || die "the range has no commits: $RANGE"
ORIGINAL=$(git symbolic-ref --short -q HEAD 2> /dev/null || git rev-parse --short HEAD)

if [ -n "$BRANCH" ]; then
  git rev-parse --verify -q "refs/heads/$BRANCH" > /dev/null || die "no such branch: $BRANCH"
  if [ "$BRANCH" != "$ORIGINAL" ]; then
    [ -z "$(git status --porcelain 2> /dev/null)" ] \
      || die "the worktree has changes. Commit or stash them first."
    git checkout "$BRANCH"
  fi
fi

printf '🔎 Cherry-picking %s commit(s) from %s\n\n' "$COUNT" "$RANGE"
git log --oneline --reverse "$RANGE" | sed 's/^/   /'
printf '\n'
PICK=(cherry-pick)
if [ "$NOCOMMIT" -eq 1 ]; then
  PICK+=(-n)
fi

if ! git "${PICK[@]}" "$RANGE"; then
  printf '\n⚠️  The cherry-pick stopped. Read the message above, then run:\n' >&2
  printf '   git cherry-pick --continue\n' >&2
  printf '   To cancel: git cherry-pick --abort\n' >&2
  exit 1
fi
if [ "$NOCOMMIT" -eq 1 ]; then
  printf '\n✅ Changes are staged. Review them, then commit.\n'
else
  printf '\n✅ Cherry-pick done. New HEAD: %s\n' "$(git log -1 --format='%h %s')"
fi
if [ -n "$BRANCH" ] && [ "$BRANCH" != "$ORIGINAL" ]; then
  printf 'ℹ️  Return with: git checkout %s\n' "$ORIGINAL"
fi
