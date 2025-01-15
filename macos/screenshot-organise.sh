#!/usr/bin/env bash
set -euo pipefail
# Moves screenshots into year and month folders.
# Usage: screenshot-organise [--dir DIR] [--dry-run] [-y] [-h]
# Needs: find, stat, date
# Note: the tool moves files. Use --dry-run first.
if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi
show_help() {
  cat <<'EOF'
screenshot-organise - sort screenshots into year and month folders.

Usage: screenshot-organise [--dir DIR] [--dry-run] [--yes]

  --dir DIR   Folder to scan. Default: ~/Desktop.
  --dry-run   Show the moves. Change nothing.
  -y, --yes   Do not ask for confirmation.
  -h, --help  Show this help.

For example, a shot from May 2024 moves to 2024/05/.
EOF
}
dir=$HOME/Desktop
dry_run=0
assume_yes=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      [[ $# -ge 2 ]] || { printf 'Error: --dir needs a value.\n' >&2; exit 1; }
      dir=$2
      shift 2
      ;;
    --dry-run) dry_run=1; shift ;;
    -y | --yes) assume_yes=1; shift ;;
    -h | --help) show_help; exit 0 ;;
    *) printf 'Error: unknown argument: %s\n' "$1" >&2; show_help >&2; exit 1 ;;
  esac
done
[[ -d "$dir" ]] || { printf 'Error: the folder does not exist: %s\n' "$dir" >&2; exit 1; }
files=()
while IFS= read -r -d '' file; do
  files+=("$file")
done < <(find "$dir" -maxdepth 1 -type f \
  \( -name 'Screenshot *.png' -o -name 'Screen Shot *.png' -o -name 'Screenshot *.jpg' \) \
  -print0)
if [[ ${#files[@]} -eq 0 ]]; then
  printf '✅ No screenshots to organise in %s.\n' "$dir"
  exit 0
fi
printf '📸 Found %s screenshot(s) in %s.\n' "${#files[@]}" "$dir"
if [[ $dry_run -eq 0 && $assume_yes -eq 0 ]]; then
  printf 'Move them into year and month folders? [y/N] '
  read -r answer || answer=""
  case "$answer" in
    [yY]*) ;;
    *) printf 'Nothing changed.\n'; exit 0 ;;
  esac
fi
moved=0
for file in "${files[@]}"; do
  target="$dir/$(date -r "$(stat -f %m "$file")" +%Y/%m)"
  if [[ $dry_run -eq 1 ]]; then
    printf '  %s -> %s/\n' "$(basename "$file")" "$target"
  else
    mkdir -p "$target"
    mv "$file" "$target/"
  fi
  moved=$((moved + 1))
done
if [[ $dry_run -eq 1 ]]; then
  printf '\n🔍 Dry run. Nothing changed.\n'
else
  printf '\n✅ Moved %s file(s).\n' "$moved"
fi
