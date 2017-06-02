#!/usr/bin/env bash
set -euo pipefail

# Lists loaded kernel modules, or shows the parameters of one module.
# Usage: kernel-modules [MODULE] [-h]
# Needs: Linux /proc, lsmod

if [[ ! -r /proc/modules ]]; then
  printf 'Error: /proc/modules is missing. This tool needs Linux.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
kernel-modules - list loaded modules and their parameters.

Usage: kernel-modules [MODULE]

With no argument the tool lists every loaded module. With a module name it
shows the parameters that the module reports in /sys/module.
EOF
}

case $# in
  0) module= ;;
  1)
    if [[ $1 == -h || $1 == --help ]]; then
      show_help
      exit 0
    fi
    module=$1
    ;;
  *)
    printf 'Error: give one module name at most.\n' >&2
    exit 1
    ;;
esac

if [[ -z "$module" ]]; then
  count=$(awk 'END {print NR}' /proc/modules)
  printf '🧩 %s modules are loaded\n\n' "$count"
  if command -v lsmod >/dev/null 2>&1; then
    lsmod
  else
    awk '{printf "%-28s %8s %s\n", $1, $2, $4}' /proc/modules
  fi
  exit 0
fi

if [[ ! $module =~ ^[A-Za-z0-9_-]+$ ]]; then
  printf 'Error: invalid module name: %s\n' "$module" >&2
  exit 1
fi

dir="/sys/module/$module/parameters"
if [[ ! -d "$dir" ]]; then
  printf 'Error: module %s is not loaded.\n' "$module" >&2
  exit 1
fi

printf '🧩 Parameters for %s\n' "$module"
found=0
for param in "$dir"/*; do
  [[ -e "$param" ]] || continue
  found=1
  printf '  %-28s %s\n' "$(basename "$param")" "$(cat "$param" 2>/dev/null || printf '(not readable)')"
done
if [[ $found -eq 0 ]]; then
  printf '  This module has no parameters.\n'
fi
