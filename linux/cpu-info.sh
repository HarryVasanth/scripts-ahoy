#!/usr/bin/env bash
set -euo pipefail

# Shows the CPU model, core count, flags and current frequency.
# Usage: cpu-info [-h]
# Needs: Linux /proc

if [[ ! -r /proc/cpuinfo ]]; then
  printf 'Error: /proc/cpuinfo is missing. This tool needs Linux.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
cpu-info - show the CPU model, cores, flags and frequency.

Usage: cpu-info

The tool reads /proc/cpuinfo. Some ARM systems do not report a model name or
a frequency. In that case the line shows "unknown".
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h | --help) show_help; exit 0 ;;
    *) printf 'Error: unknown argument: %s\n' "$arg" >&2; show_help >&2; exit 1 ;;
  esac
done

model=$(awk -F': ' '/^model name/ {print $2; exit}' /proc/cpuinfo)
if [[ -z "$model" ]]; then
  model=$(awk -F': ' '/^(Hardware|Model)/ {print $2; exit}' /proc/cpuinfo)
fi
cores=$(getconf _NPROCESSORS_ONLN 2>/dev/null || awk '/^processor/ {n++} END {print n + 0}' /proc/cpuinfo)
flags=$(awk -F': ' '/^(flags|Features)/ {print $2; exit}' /proc/cpuinfo)
mhz=$(awk -F': ' '/^cpu MHz/ {printf "%.0f", $2; exit}' /proc/cpuinfo)

printf '🖥️  Model: %s\n' "${model:-unknown}"
printf '   Cores: %s\n' "$cores"
if [[ -n "$mhz" ]]; then
  printf '   Speed: %s MHz (current)\n' "$mhz"
else
  printf '   Speed: unknown\n'
fi

if [[ -n "$flags" ]]; then
  printf '   Flags: %s\n' "$(printf '%s' "$flags" | wc -w | tr -d ' ')"
  printf '%s\n' "$flags" | fold -s -w 68 | sed 's/^/          /'
else
  printf '   Flags: not reported\n'
fi
