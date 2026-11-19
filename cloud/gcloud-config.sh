#!/usr/bin/env bash
# List, show or activate gcloud configurations.
# Usage: gcloud-config [--current] [CONFIGURATION]
# Needs: gcloud
set -euo pipefail

usage() {
  cat << 'EOF'
Usage: gcloud-config [--current] [CONFIGURATION]

With no argument, list every configuration. With a name, activate it
and show the account and project.

  --current   Show the active configuration and account.
  -h, --help  Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

current=0
name=""
while (($# > 0)); do
  case "$1" in
    --current) current=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*) die "Unknown option: $1" ;;
    *)
      [[ -z "$name" ]] || die 'Pass one configuration only.'
      name="$1"
      ;;
  esac
  shift
done

command -v gcloud > /dev/null 2>&1 \
  || die 'gcloud is not installed. Install it: https://cloud.google.com/sdk/docs/install'

if ((current == 1)); then
  gcloud config configurations list --filter='IS_ACTIVE:true' 2> /dev/null || die 'Cannot read the gcloud configuration. Run: gcloud init'
  account=$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2> /dev/null || true)
  [[ -n "$account" ]] || printf '⚠️  No active account. Run: gcloud auth login\n' >&2
  exit 0
fi

if [[ -z "$name" ]]; then
  gcloud config configurations list || die 'Cannot read the gcloud configuration. Run: gcloud init'
  exit 0
fi

known=$(gcloud config configurations list --format='value(name)' 2> /dev/null | grep -Fx "$name" || true)
if [[ -z "$known" ]]; then
  printf '❌ Unknown configuration: %s\n   Known:\n' "$name" >&2
  gcloud config configurations list --format='value(name)' 2> /dev/null | sed 's/^/   /' >&2
  exit 1
fi

gcloud config configurations activate "$name" > /dev/null || die "Could not activate $name. Check the configuration file."
printf '✅ Active configuration: %s\n' "$name"
gcloud config list 2> /dev/null || true
account=$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2> /dev/null || true)
[[ -n "$account" ]] || printf '⚠️  No active account. Run: gcloud auth login\n' >&2
