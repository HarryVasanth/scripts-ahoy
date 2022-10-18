#!/usr/bin/env bash
# Show the current shell, its version, its options, and a PATH summary.
# Usage: shell-info.sh

set -euo pipefail

case "${1:-}" in
  -h|--help)
    cat <<'EOF'
Show facts about the current shell.
Usage: shell-info.sh

Prints the login shell, the bash version, the active options, and each
PATH entry with a mark when the directory is missing.
EOF
    exit 0 ;;
  "") ;;
  *) printf 'error: unexpected argument %s\n' "$1" >&2; exit 1 ;;
esac

printf '🐚 Login shell: %s\n' "${SHELL:-unknown}"
printf '🧩 Bash version: %s\n' "${BASH_VERSION:-not bash}"
printf '⚙️  Options: %s\n' "$-"
if [[ "$-" == *i* ]]; then
  printf '🖥️  Mode: interactive\n'
else
  printf '🖥️  Mode: non-interactive\n'
fi

count=0
missing=0
printf '🛤️  PATH entries:\n'
while IFS= read -r dir; do
  if [[ -z "$dir" ]]; then
    dir="."
  fi
  count=$((count + 1))
  if [[ -d "$dir" ]]; then
    printf '  ✅ %s\n' "$dir"
  else
    printf '  ❌ %s\n' "$dir"
    missing=$((missing + 1))
  fi
done <<EOF
$(printf '%s' "$PATH" | tr ':' '\n')
EOF

printf '📊 %d entries, %d missing\n' "$count" "$missing"
