#!/usr/bin/env bash
# Report SSD TRIM support and the last trim, or run a trim pass.
# Usage: ssd-trim.sh [--run] [--dry-run] [MOUNT...]
# Needs: lsblk, fstrim (util-linux)
# Note: --run needs root. The default is read-only.

set -euo pipefail

run=0
dry=0
mounts=()
while (($# > 0)); do
  case "$1" in
    --run) run=1 ;;
    --dry-run) dry=1 ;;
    -h | --help)
      sed -n '2,5p' "$0" | sed 's/^# //'
      exit 0
      ;;
    -*)
      printf '[-] Unknown option: %s\n' "$1" >&2
      exit 2
      ;;
    *) mounts+=("$1") ;;
  esac
  shift
done

if [[ "$(uname -s)" != "Linux" ]]; then
  printf '[-] This script only runs on Linux. 🐧\n' >&2
  exit 1
fi
if ! command -v lsblk > /dev/null 2>&1; then
  printf '[-] lsblk is missing. Install util-linux.\n' >&2
  exit 1
fi
if ((${#mounts[@]} == 0)); then
  mounts=(/)
fi

printf '💽 TRIM report\n\n'
for mount in "${mounts[@]}"; do
  if [[ ! -d $mount ]]; then
    printf '⚠️  %s is not a directory. Skip.\n' "$mount" >&2
    continue
  fi
  device=$(findmnt -no SOURCE --target "$mount" 2> /dev/null || true)
  if [[ -z $device ]]; then
    printf '⚠️  %s is not a mount point. Skip.\n' "$mount" >&2
    continue
  fi
  base=${device%%\[*}
  printf '📂 %s → %s\n' "$mount" "$base"
  if lsblk -Dno DISC-GRAN "$base" 2> /dev/null | grep -qv '^0B$'; then
    printf '   ✅ Discard is supported.\n'
  else
    printf '   ⚠️  Discard looks unsupported or is hidden by the device stack.\n'
  fi
done

if command -v systemctl > /dev/null 2>&1; then
  state=$(systemctl is-enabled fstrim.timer 2> /dev/null || true)
  printf '\n⏱️  fstrim.timer: %s\n' "${state:-not found}"
fi

if ((run == 0)); then
  printf '\n[*] Read-only report. Add --run to trim now.\n'
  exit 0
fi
if ((EUID != 0)); then
  printf '[-] --run needs root. Try: sudo %s --run\n' "$0" >&2
  exit 1
fi
if ((dry == 1)); then
  printf '\n[*] Dry run. Nothing was trimmed.\n'
  exit 0
fi

printf '\n🧹 Trimming %s ...\n' "${mounts[*]}"
fstrim -v "${mounts[@]}"
printf '✅ Trim finished.\n'
