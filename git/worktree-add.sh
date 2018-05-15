#!/usr/bin/env bash
# Add a git worktree for a branch.
# Usage: worktree-add.sh BRANCH [-d DIR] [--from REF] [-h]
# Needs: git

set -euo pipefail

BRANCH=
DIR=
FROM=HEAD

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -d) [ "$#" -ge 2 ] || die "-d needs a path."; DIR=$2; shift 2 ;;
    --from) [ "$#" -ge 2 ] || die "--from needs a ref."; FROM=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option $1" ;;
    *) [ -z "$BRANCH" ] || die "give one branch name."; BRANCH=$1; shift ;;
  esac
done

[ -n "$BRANCH" ] || die "give a branch name."
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "this is not a git repository."
git check-ref-format --branch "$BRANCH" >/dev/null 2>&1 || die "invalid branch name: $BRANCH"

ROOT=$(git rev-parse --show-toplevel)
if [ -z "$DIR" ]; then
  SAFE=$(printf '%s' "$BRANCH" | tr '/' '-')
  DIR="$(dirname "$ROOT")/$(basename "$ROOT")-$SAFE"
fi
[ -e "$DIR" ] && die "the path already exists: $DIR"

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  git worktree add "$DIR" "$BRANCH"
else
  git rev-parse --verify -q HEAD >/dev/null || die "no commits yet. Make a commit first."
  git rev-parse --verify -q "$FROM" >/dev/null || die "unknown ref: $FROM"
  git worktree add -b "$BRANCH" "$DIR" "$FROM"
fi

printf '✅ Worktree ready: %s\n' "$DIR"
printf '   Next: cd "%s"\n' "$DIR"
