#!/usr/bin/env bash
# Run ShellCheck on every shell script in a tree.
# Usage: shellcheck-all.sh [-d DIR]
# Needs: shellcheck

set -euo pipefail

dir="."

usage() {
  cat <<'EOF'
Check all shell scripts with ShellCheck.
Usage: shellcheck-all.sh [-d DIR]

  -d, --dir DIR   directory to search (default: .)
  -h, --help      show this help

The search is recursive and skips .git. Files ending in .sh or .bash
are checked. The exit code is 1 when any file has a finding.
EOF
}

while (($# > 0)); do
  case "$1" in
    -d|--dir)
      (($# >= 2)) || { printf 'error: %s needs a directory\n' "$1" >&2; exit 1; }
      dir="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) printf 'error: unknown option %s\n' "$1" >&2; exit 1 ;;
    *) printf 'error: unexpected argument %s\n' "$1" >&2; exit 1 ;;
  esac
done

[[ -d "$dir" ]] || { printf 'error: %s is not a directory\n' "$dir" >&2; exit 1; }
command -v shellcheck >/dev/null 2>&1 ||
  { printf 'error: ShellCheck is not installed\n  macOS: brew install shellcheck\n  Linux: apt-get install shellcheck\n' >&2; exit 1; }

count=0
failed=0
while IFS= read -r -d '' file; do
  count=$((count + 1))
  if ! shellcheck "$file"; then
    failed=$((failed + 1))
    printf '❌ %s\n' "$file" >&2
  fi
done < <(find "$dir" -type f \( -name '*.sh' -o -name '*.bash' \) -not -path '*/.git/*' -print0)

printf '🧪 Checked %d file(s): %d clean, %d with findings\n' "$count" "$((count - failed))" "$failed"
if ((failed > 0)); then
  exit 1
fi
