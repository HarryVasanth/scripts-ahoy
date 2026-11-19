#!/usr/bin/env bash
# Show the top authors for a file or line range.
# Usage: blame-summary.sh [-n COUNT] [-L START,END] FILE
# Needs: git

set -euo pipefail

TOP=10
RANGE=
FILE=

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n)
      [ "$#" -ge 2 ] || die "-n needs a number."
      TOP=$2
      shift 2
      ;;
    -L)
      [ "$#" -ge 2 ] || die "-L needs START,END."
      RANGE=$2
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "unknown option $1" ;;
    *)
      [ -z "$FILE" ] || die "give one file only."
      FILE=$1
      shift
      ;;
  esac
done

case "$TOP" in
  '' | *[!0-9]* | 0) die "-n needs a number above zero." ;;
esac

[ -n "$FILE" ] || die "give a file. See --help."

case "$RANGE" in
  '') ;;
  *[!0-9,]*) die "-L needs START,END with numbers." ;;
  *,*) ;;
  *) die "-L needs START,END." ;;
esac

git rev-parse --git-dir > /dev/null 2>&1 || die "this is not a git repository."
[ -f "$FILE" ] || die "no such file: $FILE"
git cat-file -e "HEAD:$FILE" 2> /dev/null || die "not a tracked file: $FILE"

ARGS=(--line-porcelain -w)
if [ -n "$RANGE" ]; then
  ARGS+=(-L "$RANGE")
fi

printf '🔎 Blame summary for %s\n\n' "$FILE"
git blame "${ARGS[@]}" -- "$FILE" \
  | awk '/^author / { name = substr($0, 8); count[name]++ }
    END { for (n in count) printf "%d\t%s\n", count[n], n }' \
  | sort -rn \
  | head -n "$TOP" \
  | awk -F'\t' '{ printf "  %5d  %s\n", $1, $2 }'
