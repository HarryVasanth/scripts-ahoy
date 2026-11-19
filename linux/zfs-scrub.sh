#!/usr/bin/env bash
set -euo pipefail

# Shows or controls ZFS pool scrubs.
# Usage: zfs-scrub [--start|--stop|--status] [POOL...] [-h]
# Needs: zpool (zfsutils-linux)

show_help() {
  cat << 'EOF'
zfs-scrub - start, stop or show a ZFS scrub.

Usage: zfs-scrub [--start|--stop|--status] [POOL...]

  --status   Show the pool status. This is the default action.
  --start    Start a scrub on each pool.
  --stop     Cancel a running scrub.
  -h, --help Show this help.

With no pool name the tool uses every pool.
EOF
}

if ! command -v zpool > /dev/null 2>&1; then
  printf 'Error: zpool is missing. Install zfsutils-linux (or zfs on FreeBSD).\n' >&2
  exit 1
fi

action="status"
pools=()
for arg in "$@"; do
  case "$arg" in
    --start) action="start" ;;
    --stop) action="stop" ;;
    --status) action="status" ;;
    -h | --help)
      show_help
      exit 0
      ;;
    -*)
      printf 'Error: unknown argument: %s\n' "$arg" >&2
      exit 1
      ;;
    *) pools+=("$arg") ;;
  esac
done

if [[ ${#pools[@]} -eq 0 ]]; then
  while IFS= read -r name; do
    [[ -n "$name" ]] && pools+=("$name")
  done < <(zpool list -H -o name)
fi

if [[ ${#pools[@]} -eq 0 ]]; then
  printf 'Error: no ZFS pool found.\n' >&2
  exit 1
fi

for pool in "${pools[@]}"; do
  case "$action" in
    start)
      printf '🧹 Starting a scrub on %s...\n' "$pool"
      zpool scrub "$pool"
      ;;
    stop)
      printf '🛑 Stopping the scrub on %s...\n' "$pool"
      zpool scrub -s "$pool"
      ;;
    status)
      zpool status "$pool"
      printf '\n'
      ;;
  esac
done

if [[ "$action" = "status" ]]; then
  printf '💡 Start a scrub with: %s --start\n' "$(basename "$0")"
fi
