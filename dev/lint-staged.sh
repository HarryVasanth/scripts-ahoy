#!/usr/bin/env bash
# Run linters on staged files.
# Usage: lint-staged
# Needs: git, plus the linters you use (eslint, flake8, gofmt, shellcheck)

set -euo pipefail

usage() {
  cat << 'EOF'
Usage: lint-staged

Run the matching linter on each staged file. A missing linter is skipped.
Staged files come from the index.
  -h, --help  Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi
(($# == 0)) || die "Unexpected argument: $1"

command -v git > /dev/null 2>&1 || die 'git is not installed.'
git rev-parse --is-inside-work-tree > /dev/null 2>&1 \
  || die 'Run this inside a git work tree.'

tmp=$(mktemp "${TMPDIR:-/tmp}/lint-staged.XXXXXX")
trap 'rm -f "$tmp"' EXIT
git diff --cached --name-only --diff-filter=ACMR > "$tmp"

if [[ ! -s "$tmp" ]]; then
  printf 'ℹ️  No staged files to check.\n' >&2
  exit 0
fi

fail=0
while IFS= read -r file; do
  [[ -f "$file" ]] || continue
  case "$file" in
    *.js | *.jsx | *.ts | *.tsx)
      command -v eslint > /dev/null 2>&1 || continue
      printf '🔍 eslint %s\n' "$file"
      eslint "$file" || fail=1
      ;;
    *.py)
      command -v flake8 > /dev/null 2>&1 || continue
      printf '🔍 flake8 %s\n' "$file"
      flake8 "$file" || fail=1
      ;;
    *.go)
      command -v gofmt > /dev/null 2>&1 || continue
      if [[ -n "$(gofmt -l "$file")" ]]; then
        printf '❌ gofmt %s needs formatting\n' "$file"
        fail=1
      fi
      ;;
    *.sh)
      command -v shellcheck > /dev/null 2>&1 || continue
      printf '🔍 shellcheck %s\n' "$file"
      shellcheck "$file" || fail=1
      ;;
  esac
done < "$tmp"

if ((fail != 0)); then
  printf '❌ Some staged files have problems.\n' >&2
  exit 1
fi
printf '✅ Staged files look clean.\n'
