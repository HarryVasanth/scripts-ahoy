#!/usr/bin/env bash
# Check or apply terraform fmt across a directory tree.
# Usage: terraform-fmt [--write] [--diff] [directory]
# Needs: terraform

set -euo pipefail

usage() {
  cat << 'EOF'
Usage: terraform-fmt [--write] [--diff] [directory]

With no flags, check the format and exit 1 when a file needs a change.
The check is quiet when every file is clean.

  --write     Rewrite the files in place.
  --diff      Show a diff for each file that needs a change.
  -h, --help  Show this help.
EOF
}

write=0
diff=0
dir="."

while (($# > 0)); do
  case "$1" in
    --write) write=1 ;;
    --diff) diff=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      printf '❌ Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
    *) dir="$1" ;;
  esac
  shift
done

if ! command -v terraform > /dev/null 2>&1; then
  printf '❌ terraform is not installed. Install it: https://developer.hashicorp.com/terraform/install\n' >&2
  exit 1
fi

if [[ ! -d "$dir" ]]; then
  printf '❌ Directory not found: %s\n' "$dir" >&2
  exit 1
fi

args=(-recursive)

if ((write == 1)); then
  terraform fmt "${args[@]}" "$dir"
  printf '✅ Formatting applied.\n' >&2
  exit 0
fi

if ((diff == 1)); then
  args+=(-diff)
fi
args+=(-check)

if terraform fmt "${args[@]}" "$dir"; then
  printf '✅ All files are formatted.\n' >&2
  exit 0
fi

printf '❌ Some files need formatting. Run this script with --write.\n' >&2
exit 1
