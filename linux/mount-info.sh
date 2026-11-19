#!/usr/bin/env bash
set -euo pipefail

# Lists mounts with the file system type, size and options.
# Usage: mount-info [MOUNTPOINT] [-h]
# Needs: findmnt (util-linux) or df

if [[ $(uname -s) != Linux ]]; then
  printf 'Error: this tool needs Linux.\n' >&2
  exit 1
fi

show_help() {
  cat << 'EOF'
mount-info - list mounts with their type, size and options.

Usage: mount-info [MOUNTPOINT]

With no argument the tool lists every mount. With a mount point it shows only
that entry. The tool uses findmnt when it is available and falls back to df.
EOF
}

target=
for arg in "$@"; do
  case "$arg" in
    -h | --help)
      show_help
      exit 0
      ;;
    -*)
      printf 'Error: unknown argument: %s\n' "$arg" >&2
      show_help >&2
      exit 1
      ;;
    *)
      if [[ -n "$target" ]]; then
        printf 'Error: give one mount point at most.\n' >&2
        exit 1
      fi
      target=$arg
      ;;
  esac
done

if command -v findmnt > /dev/null 2>&1; then
  if [[ -n "$target" ]]; then
    if ! findmnt -o TARGET,SOURCE,FSTYPE,SIZE,USED,AVAIL,OPTIONS "$target"; then
      printf 'Error: no mount found for %s\n' "$target" >&2
      exit 1
    fi
  else
    findmnt -o TARGET,SOURCE,FSTYPE,SIZE,USED,AVAIL,OPTIONS
  fi
  exit 0
fi

printf 'Note: findmnt is not installed. The output comes from df and mount.\n' >&2
if [[ -n "$target" ]]; then
  df -h "$target"
else
  df -h
fi
printf '\nOptions:\n'
mount
