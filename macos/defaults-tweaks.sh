#!/usr/bin/env bash
set -euo pipefail
# Applies a small set of useful macOS defaults settings.
# Usage: defaults-tweaks --list | --apply [--dry-run] [-y] [-h]
# Note: restart Finder and Dock, or log out, to see every change.
if [[ $(uname -s) != Darwin ]]; then
  printf 'Error: this tool needs macOS.\n' >&2
  exit 1
fi
show_help() {
  cat << 'EOF'
defaults-tweaks - useful macOS defaults, in one place.

Usage: defaults-tweaks --list
       defaults-tweaks --apply [--dry-run] [--yes]

  --list      Show each setting and its current value.
  --apply     Write the settings. Asks first.
  --dry-run   Show the commands. Change nothing.
  -y, --yes   Do not ask for confirmation.
  -h, --help  Show this help.
EOF
}
tweaks=(
  "com.apple.finder|AppleShowAllFiles|bool|true|Show hidden files in Finder"
  "com.apple.finder|ShowPathbar|bool|true|Show the path bar in Finder"
  "com.apple.finder|_FXShowPosixPathInTitle|bool|true|Show the full path in the title"
  "NSGlobalDomain|AppleShowAllExtensions|bool|true|Show all file extensions"
  "NSGlobalDomain|ApplePressAndHoldEnabled|bool|false|Repeat a held key, no accent menu"
  "NSGlobalDomain|KeyRepeat|int|2|Use a fast key repeat"
  "com.apple.dock|autohide|bool|true|Hide the Dock until you point at it"
)
action=""
dry_run=0
assume_yes=0
for arg in "$@"; do
  case "$arg" in
    --list) action="list" ;;
    --apply) action="apply" ;;
    --dry-run) dry_run=1 ;;
    -y | --yes) assume_yes=1 ;;
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
[[ -n "$action" ]] || {
  printf 'Error: give --list or --apply.\n' >&2
  show_help >&2
  exit 1
}
if [[ "$action" = "list" ]]; then
  for tweak in "${tweaks[@]}"; do
    IFS='|' read -r domain key _ _ desc <<< "$tweak"
    current=$(defaults read "$domain" "$key" 2> /dev/null || printf '(not set)')
    printf '%s\n  %s %s = %s\n' "$desc" "$domain" "$key" "$current"
  done
  exit 0
fi
if [[ $dry_run -eq 0 && $assume_yes -eq 0 ]]; then
  printf 'Apply these %s settings? [y/N] ' "${#tweaks[@]}"
  read -r answer || answer=""
  case "$answer" in
    [yY]*) ;;
    *)
      printf 'Nothing changed.\n'
      exit 0
      ;;
  esac
fi
for tweak in "${tweaks[@]}"; do
  IFS='|' read -r domain key kind value desc <<< "$tweak"
  if [[ $dry_run -eq 1 ]]; then
    printf 'defaults write %s %s -%s %s\n' "$domain" "$key" "$kind" "$value"
  else
    defaults write "$domain" "$key" "-$kind" "$value"
    printf '✅ %s\n' "$desc"
  fi
done
if [[ $dry_run -eq 1 ]]; then
  printf '\n🔍 Dry run. Nothing changed.\n'
else
  printf '\n💡 Some changes need a restart of Finder or Dock.\n'
fi
