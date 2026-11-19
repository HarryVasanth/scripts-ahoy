#!/usr/bin/env bash
set -euo pipefail
# Removes the quarantine flag from downloaded files.
# Usage: quarantine-clear [--dry-run] [-y] [-r] PATH... [-h]
# Needs: find, xattr
# Note: remove the flag only for files that you trust.
if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi
show_help() {
  cat << 'EOF'
quarantine-clear - remove the quarantine flag from files.

Usage: quarantine-clear [--dry-run] [--yes] [--recursive] PATH...

  --dry-run        List the files. Change nothing.
  -y, --yes        Do not ask for confirmation.
  -r, --recursive  Look inside folders.
  -h, --help       Show this help.
EOF
}
dry_run=0
assume_yes=0
recursive=0
paths=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
      shift
      ;;
    -y | --yes)
      assume_yes=1
      shift
      ;;
    -r | --recursive)
      recursive=1
      shift
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    -*)
      printf 'Error: unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
    *)
      paths+=("$1")
      shift
      ;;
  esac
done
[[ ${#paths[@]} -gt 0 ]] || {
  printf 'Error: give at least one file or folder.\n' >&2
  show_help >&2
  exit 1
}
for path in "${paths[@]}"; do
  [[ -e "$path" ]] || {
    printf 'Error: path not found: %s\n' "$path" >&2
    exit 1
  }
done
if [[ $recursive -eq 1 ]]; then
  finder() { find "$1" -type f -print0; }
else
  finder() { find "$1" -maxdepth 1 -type f -print0; }
fi
found=()
for path in "${paths[@]}"; do
  while IFS= read -r -d '' file; do
    if xattr -p com.apple.quarantine "$file" > /dev/null 2>&1; then
      found+=("$file")
    fi
  done < <(finder "$path")
done
if [[ ${#found[@]} -eq 0 ]]; then
  printf '✅ No quarantined files found.\n'
  exit 0
fi
printf '🔎 Found %s quarantined file(s):\n' "${#found[@]}"
for file in "${found[@]}"; do
  printf '  %s\n' "$file"
done
if [[ $dry_run -eq 0 && $assume_yes -eq 0 ]]; then
  printf 'Remove the flag from these files? [y/N] '
  read -r answer || answer=""
  case "$answer" in
    [yY]*) ;;
    *)
      printf 'Nothing changed.\n'
      exit 0
      ;;
  esac
fi
for file in "${found[@]}"; do
  xattr -d com.apple.quarantine "$file"
done
if [[ $dry_run -eq 1 ]]; then
  printf '\n🔍 Dry run. Nothing changed.\n'
else
  printf '\n✅ Cleared the flag on %s file(s).\n' "${#found[@]}"
fi
