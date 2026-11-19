#!/usr/bin/env bash
# Update a fork from its upstream remote and push.
# Usage: sync-fork.sh [-u UPSTREAM] [-b BRANCH] [--rebase] [-y] [-h]
# Needs: git
# Note: It asks before it pushes. It never force-pushes.

set -euo pipefail

UPSTREAM=upstream
BRANCH=
USE_REBASE=0
ASSUME_YES=0

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -u)
      [ "$#" -ge 2 ] || die "-u needs a remote."
      UPSTREAM=$2
      shift 2
      ;;
    -b)
      [ "$#" -ge 2 ] || die "-b needs a branch."
      BRANCH=$2
      shift 2
      ;;
    --rebase)
      USE_REBASE=1
      shift
      ;;
    -y | --yes)
      ASSUME_YES=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "unknown option $1" ;;
  esac
done

git rev-parse --is-inside-work-tree > /dev/null 2>&1 || die "this is not a git repository."
git remote get-url "$UPSTREAM" > /dev/null 2>&1 \
  || die "no remote called $UPSTREAM. Add one with: git remote add upstream URL"
if [ -n "$(git status --porcelain 2> /dev/null)" ]; then
  die "the worktree has changes. Commit or stash them first."
fi

printf '🔄 Fetching %s\n' "$UPSTREAM"
git fetch "$UPSTREAM" --prune
if [ -z "$BRANCH" ]; then
  BRANCH=$(git symbolic-ref --short -q HEAD 2> /dev/null || true)
fi
if [ -z "$BRANCH" ]; then
  if git rev-parse --verify -q "refs/remotes/$UPSTREAM/main" > /dev/null; then
    BRANCH=main
  elif git rev-parse --verify -q "refs/remotes/$UPSTREAM/master" > /dev/null; then
    BRANCH=master
  else
    die "detached HEAD. Use -b BRANCH."
  fi
fi
git rev-parse --verify -q "refs/remotes/$UPSTREAM/$BRANCH" > /dev/null \
  || die "$UPSTREAM has no branch called $BRANCH"

CURRENT=$(git symbolic-ref --short -q HEAD 2> /dev/null || true)
if [ "$CURRENT" != "$BRANCH" ]; then
  git checkout "$BRANCH"
fi

if [ "$USE_REBASE" -eq 1 ]; then
  git rebase "$UPSTREAM/$BRANCH"
else
  git merge --ff-only "$UPSTREAM/$BRANCH" \
    || die "cannot fast-forward. Local commits exist. Re-run with --rebase."
fi

if ! git remote get-url origin > /dev/null 2>&1; then
  printf 'ℹ️  No origin remote. The push is skipped.\n'
  exit 0
fi
if [ "$ASSUME_YES" -eq 0 ]; then
  printf 'Push %s to origin? [y/N] ' "$BRANCH"
  read -r reply
  case "$reply" in
    y | Y | yes) ;;
    *)
      printf 'Push skipped.\n'
      exit 0
      ;;
  esac
fi
git push origin "$BRANCH"
printf '✅ %s is up to date with %s.\n' "$BRANCH" "$UPSTREAM"
