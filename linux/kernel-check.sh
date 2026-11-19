#!/usr/bin/env bash
set -euo pipefail

# Compares the running kernel with the newest installed one.
# Usage: kernel-check [-h]
# Needs: uname, sort
# Note: a pending reboot is a normal result. The exit status stays 0.

if [[ $(uname -s) != Linux ]]; then
  printf 'Error: this tool needs Linux.\n' >&2
  exit 1
fi

show_help() {
  cat << 'EOF'
kernel-check - check the running kernel and pending reboots.

Usage: kernel-check

The tool shows the running kernel, the newest installed kernel and whether
a reboot is pending. Reboot markers such as /var/run/reboot-required count.
EOF
}

for arg in "$@"; do
  case "$arg" in
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

running=$(uname -r)
printf 'Running kernel: %s\n' "$running"

newest=""
if compgen -G "/boot/vmlinuz-*" > /dev/null 2>&1; then
  newest=$(for f in /boot/vmlinuz-*; do basename "$f"; done \
    | sed 's/^vmlinuz-//' | sort -V | tail -n 1)
  printf 'Newest kernel:  %s\n' "$newest"
else
  printf 'Newest kernel:  unknown (no kernel images in /boot)\n'
fi

reboot=0
for marker in /var/run/reboot-required /run/reboot-required; do
  if [[ -f "$marker" ]]; then
    printf '\n⚠️  A reboot is required. The marker %s exists.\n' "$marker"
    reboot=1
    break
  fi
done

if [[ -n "$newest" && "$newest" != "$running" ]]; then
  printf '\n⚠️  A newer kernel is installed. Reboot to use it.\n'
  reboot=1
fi

if [[ $reboot -eq 0 ]]; then
  printf '\n✅ The running kernel is current.\n'
fi
