#!/usr/bin/env bash
# Delete old items from a temporary directory.
# Usage: clean-temp.sh [-d DAYS] [--dry-run] [--yes] [DIR]
# Note: DIR defaults to /tmp. The script asks before it deletes.

set -euo pipefail

days=7
dir="${TMPDIR:-/tmp}"
dry=0
yes=0

usage() {
  cat << 'EOF'
Remove old entries at the top of a temporary directory.
Usage: clean-temp.sh [-d DAYS] [--dry-run] [--yes] [DIR]

  -d DAYS     age in days before an entry goes (default: 7)
  --dry-run   show what would go and stop
  --yes       do not ask for confirmation
  -h, --help  show this help

Only the top level of DIR is touched.
EOF
}

while (($# > 0)); do
  case "$1" in
    -d | --days)
      (($# >= 2)) || {
        printf 'error: %s needs a value\n' "$1" >&2
        exit 1
      }
      days="$2"
      shift
      ;;
    --dry-run) dry=1 ;;
    --yes) yes=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      printf 'error: unknown option %s\n' "$1" >&2
      exit 1
      ;;
    *) break ;;
  esac
  shift
done

(($# <= 1)) || {
  printf 'error: give one directory only\n' >&2
  exit 1
}
[[ "$days" =~ ^[0-9]+$ ]] || {
  printf 'error: DAYS must be a whole number\n' >&2
  exit 1
}
if (($# == 1)); then dir="$1"; fi
dir="${dir%/}"
[[ -n "$dir" ]] || dir="/"
[[ -d "$dir" ]] || {
  printf 'error: %s is not a directory\n' "$dir" >&2
  exit 1
}
if [[ "$dir" == "/" || "$dir" == "/System" || "$dir" == "$HOME" ]]; then
  printf 'error: %s is too important to clean\n' "$dir" >&2
  exit 1
fi

list=$(mktemp "${TMPDIR:-/tmp}/clean-temp.XXXXXX")
trap 'rm -f -- "$list"' EXIT
find "$dir" -mindepth 1 -maxdepth 1 -mtime +"$days" -print > "$list"
count=$(wc -l < "$list" | tr -d ' ')

if ((count == 0)); then
  printf '✅ Nothing older than %d day(s) in %s\n' "$days" "$dir" >&2
  exit 0
elif ((dry)); then
  printf '📝 Would remove %d item(s) from %s:\n' "$count" "$dir" >&2
  sed 's/^/   /' "$list" >&2
  exit 0
fi

if ((!yes)); then
  printf '⚠️  Remove %d item(s) from %s? [y/N] ' "$count" "$dir" >&2
  answer=""
  read -r answer || true
  case "$answer" in
    y | Y | yes | YES) ;;
    *)
      printf 'Cancelled. Nothing was deleted.\n' >&2
      exit 1
      ;;
  esac
fi

while IFS= read -r item; do
  [[ -n "$item" ]] || continue
  rm -rf -- "$item"
done < "$list"
printf '🧹 Removed %d item(s) from %s\n' "$count" "$dir" >&2
