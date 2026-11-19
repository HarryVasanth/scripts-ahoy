#!/usr/bin/env bash
set -euo pipefail

# Reports disk SMART health and file system usage.
# Usage: disk-health [-a|--all] [-h]
# Needs: lsblk, df, smartctl (smartmontools) for SMART data
# Note: SMART data can need root. Run it with sudo when the status is unknown.

if [[ $(uname -s) != Linux ]]; then
  printf 'Error: this tool needs Linux.\n' >&2
  exit 1
fi

show_help() {
  cat << 'EOF'
disk-health - show disk health and file system usage.

Usage: disk-health [--all]

  -a, --all   Show every file system, not only the full ones.
  -h, --help  Show this help.

A file system is reported when it is 80 percent full or more.
EOF
}

show_all=0
for arg in "$@"; do
  case "$arg" in
    -a | --all) show_all=1 ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      printf 'Error: unknown argument: %s\n' "$arg" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

if command -v smartctl > /dev/null 2>&1 && command -v lsblk > /dev/null 2>&1; then
  printf 'SMART health:\n'
  while read -r name; do
    [[ -z "$name" ]] && continue
    status=$(smartctl -H "/dev/$name" 2> /dev/null \
      | awk -F': ' '/overall-health|SMART Health Status/ {print $2; exit}')
    printf '  %-12s %s\n' "$name" "${status:-unknown (run with sudo)}"
  done < <(lsblk -dno NAME,TYPE | awk '$2 == "disk" {print $1}')
else
  printf 'smartctl is missing. Install smartmontools to read SMART data:\n'
  printf '  sudo apt install smartmontools   (or dnf, pacman, zypper)\n'
fi

printf '\nFile systems:\n'
if [[ $show_all -eq 1 ]]; then
  df -hP
  exit 0
fi

full=$(df -hP | awk 'NR > 1 && $5+0 >= 80')
if [[ -z "$full" ]]; then
  printf '✅ No file system is 80 percent full or more.\n'
  exit 0
fi

printf '%s\n' "$full"
