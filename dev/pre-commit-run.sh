#!/usr/bin/env bash
# Run the pre-commit hooks on all files.
# Usage: pre-commit-run [ARGS...]
# Needs: pre-commit

set -euo pipefail

usage() {
  cat << 'EOF'
Usage: pre-commit-run [ARGS...]

Run every hook in .pre-commit-config.yaml on all files.
Extra arguments go to "pre-commit run".

  -h, --help  Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

for arg in "$@"; do
  case "$arg" in
    -h | --help)
      usage
      exit 0
      ;;
  esac
done

[[ -f .pre-commit-config.yaml ]] \
  || die 'No .pre-commit-config.yaml here. Run "pre-commit install" first.'
command -v pre-commit > /dev/null 2>&1 \
  || die 'pre-commit is not installed. Try: pip install pre-commit'

printf '🪝 Running all hooks\n'
pre-commit run --all-files "$@" || die 'One or more hooks failed. Read the output above.'
printf '✅ All hooks passed.\n'
