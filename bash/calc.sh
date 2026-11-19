#!/usr/bin/env bash
# Do safe arithmetic on an expression with awk.
# Usage: calc.sh EXPRESSION

set -euo pipefail

usage() {
  cat << 'EOF'
Calculate a simple expression.
Usage: calc.sh EXPRESSION

Numbers and these operators are allowed: + - * / % ( ) ^
Put the expression in quotes to protect the shell characters.
^ is a power in awk, not a bitwise operator.

Example: calc.sh '(2 + 3) * 4 / 2'
EOF
}

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
esac

(($# == 1)) || {
  printf 'error: give one expression in quotes\n' >&2
  usage >&2
  exit 1
}
expr="$1"

[[ "$expr" =~ ^[-+*/%().\ 0-9^]+$ ]] \
  || {
    printf 'error: only numbers and + - * / %% ( ) ^ are allowed\n' >&2
    exit 1
  }

# The character check above keeps quotes, letters and semicolons out, so the
# expression is safe to place in the awk program.
result=$(awk "BEGIN { printf \"%.10g\\n\", ($expr) }" 2>&1) \
  || {
    printf 'error: cannot calculate %s\n' "$expr" >&2
    exit 1
  }

printf '🧮 %s = %s\n' "$expr" "$result"
