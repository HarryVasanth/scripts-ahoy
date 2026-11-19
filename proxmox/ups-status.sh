#!/usr/bin/env bash
# Show the state of a UPS that Network UPS Tools or apcupsd reports.
# Usage: ups-status [-u UPS] [-w SECONDS]
# Needs: upsc (NUT) or apcaccess (apcupsd)

set -euo pipefail

ups=
watch=0

usage() {
  cat << 'EOF'
Print battery charge, runtime, load and input voltage.
The script uses upsc when it is present, then apcaccess.

Options:
  -u UPS        UPS name for upsc (default: the first UPS found)
  -w SECONDS    Refresh every SECONDS seconds (default: one report)
  -h, --help    Show this help
EOF
}

die() {
  printf '❌ %s\n' "$*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    -u)
      ups=${2:-}
      shift 2 || die "Option -u needs a value."
      ;;
    -w)
      watch=${2:-}
      shift 2 || die "Option -w needs a value."
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "Unknown option: $1" ;;
  esac
done

case "$watch" in
  '' | *[!0-9]*) die "The refresh interval must be a whole number." ;;
esac

if command -v upsc > /dev/null 2>&1; then
  name=${ups:-$(upsc -l 2> /dev/null | head -n 1 || true)}
  [ -n "$name" ] || die "No UPS was found. Check that the NUT driver is running."
  show() { upsc "$name" | grep -E '^(battery\.charge|battery\.runtime|battery\.voltage|ups\.load|ups\.status|input\.voltage):' || true; }
elif command -v apcaccess > /dev/null 2>&1; then
  show() { apcaccess status | grep -E '^(STATUS|BCHARGE|TIMELEFT|LOADPCT|LINEV|BATTV)' || true; }
else
  die "No UPS tool found. Install nut (upsc), or apcupsd (apcaccess)."
fi

while :; do
  printf '\n🔌 UPS status at %s\n' "$(date '+%H:%M:%S')"
  show
  if [ "$watch" -eq 0 ]; then
    break
  fi
  sleep "$watch"
done
