#!/usr/bin/env bash
# Create an annotated release tag on the latest commit.
# Usage: tag-release.sh [-m MESSAGE] TAG
# Needs: git

set -euo pipefail

MSG=
TAG=

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -m)
      [ "$#" -ge 2 ] || die "-m needs a message."
      MSG=$2
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "unknown option $1" ;;
    *)
      [ -z "$TAG" ] || die "give one tag name only."
      TAG=$1
      shift
      ;;
  esac
done

[ -n "$TAG" ] || die "give a tag name. See --help."

git rev-parse --git-dir > /dev/null 2>&1 || die "this is not a git repository."
git rev-parse --verify -q HEAD > /dev/null || die "there are no commits yet."
git check-ref-format "refs/tags/$TAG" || die "invalid tag name: $TAG"

if git rev-parse --verify -q "refs/tags/$TAG" > /dev/null; then
  die "tag $TAG already exists."
fi

if [ -z "$MSG" ]; then
  MSG="Release $TAG"
fi

git tag -a "$TAG" -m "$MSG" HEAD
printf '✅ Tag %s created on %s\n' "$TAG" "$(git log -1 --format='%h %s')"
printf '   Message: %s\n' "$MSG"
printf '\nℹ️  Push it with: git push origin %s\n' "$TAG"
