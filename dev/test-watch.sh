#!/usr/bin/env bash
# Re-run a command when files in a directory change.
# Usage: test-watch [-d DIR] [-i SECONDS] -- <command...>
# Note: Press Ctrl-C to stop. Point -d at source files. A command that writes
# into the watched tree will trigger itself.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: test-watch [-d DIR] [-i SECONDS] -- <command...>

Run the command once, then run it again after any file changes.
The watch skips .git, node_modules and .venv.

  -d, --dir DIR      Directory to watch. Default: the current directory.
  -i, --interval N   Check every N seconds. Default: 2.
  -h, --help         Show this help.

Example:
  test-watch -- npm test
EOF
}

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

dir="."
interval=2
while (($# > 0)); do
  case "$1" in
    -d|--dir|-i|--interval)
      (($# > 1)) || die "$1 needs a value."
      case "$1" in
        -d|--dir) dir="$2" ;;
        -i|--interval) interval="$2" ;;
      esac
      shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) die "Unknown option: $1" ;;
    *) break ;;
  esac
  shift
done

(($# > 0)) || { usage >&2; die 'Pass a command to run.'; }
[[ -d "$dir" ]] || die "Directory not found: $dir"
if [[ ! "$interval" =~ ^[0-9]+$ ]] || ((interval == 0)); then die 'The interval must be a positive number.'; fi

marker=$(mktemp "${TMPDIR:-/tmp}/test-watch.XXXXXX")
trap 'rm -f "$marker"' EXIT

run_once() {
  local status=0
  touch "$marker"
  printf '▶️  Running: %s\n' "$*" >&2
  set +e
  "$@"
  status=$?
  set -e
  if ((status != 0)); then
    printf '❌ Exit %d. Waiting for changes...\n' "$status" >&2
  else
    printf '✅ Passed. Waiting for changes...\n' >&2
  fi
}

run_once "$@"
while :; do
  sleep "$interval"
  changed=$(find "$dir" \( -name .git -o -name node_modules -o -name .venv \) -prune \
    -o -type f -newer "$marker" -print 2>/dev/null | head -n 1) || true
  if [[ -n "$changed" ]]; then
    printf '\n🔁 Change: %s\n' "$changed" >&2
    run_once "$@"
  fi
done
