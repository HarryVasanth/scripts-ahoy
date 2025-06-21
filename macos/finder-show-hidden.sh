#!/usr/bin/env bash
set -euo pipefail

# Toggles or sets hidden file display in Finder.
# Usage: finder-show-hidden [--show|--hide|--status] [-h]
# Needs: defaults, killall

if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
finder-show-hidden - toggle hidden files in Finder.

Usage: finder-show-hidden [--show|--hide|--status]

  --show     Show hidden files.
  --hide     Hide hidden files.
  --status   Show the current setting only.
  -h, --help Show this help.

With no option the tool toggles the current setting. Finder restarts after a
change.
EOF
}

mode=toggle
for arg in "$@"; do
  case "$arg" in
    --show) mode=show ;;
    --hide) mode=hide ;;
    --status) mode=status ;;
    -h | --help) show_help; exit 0 ;;
    *)
      printf 'Error: unknown argument: %s\n' "$arg" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

current=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || printf '0')
case "$current" in
  1 | true | YES) state=on ;;
  *) state=off ;;
esac
if [[ $mode == status ]]; then
  if [[ $state == on ]]; then
    printf '👁️  Hidden files are shown in Finder.\n'
  else
    printf '🙈 Hidden files are hidden in Finder.\n'
  fi
  exit 0
fi

if [[ $mode == toggle ]]; then
  if [[ $state == on ]]; then mode=hide; else mode=show; fi
fi

if [[ $mode == show ]]; then
  defaults write com.apple.finder AppleShowAllFiles -bool true
  printf '👁️  Hidden files are now shown.\n'
else
  defaults write com.apple.finder AppleShowAllFiles -bool false
  printf '🙈 Hidden files are now hidden.\n'
fi

killall Finder 2>/dev/null || printf 'Note: Finder is not running.\n' >&2
