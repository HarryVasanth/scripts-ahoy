#!/usr/bin/env bash
# Show or set the active Google Cloud project.
# Usage: gcp-project [PROJECT_ID]
# Needs: gcloud

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: gcp-project [PROJECT_ID]

With no argument, print the active project from the gcloud config.
With an ID, set it as the active project.

  -h, --help  Show this help.
EOF
}

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  -*) die "Unknown option: $1" ;;
esac
(($# <= 1)) || die 'Pass one project ID only.'

command -v gcloud >/dev/null 2>&1 ||
  die 'gcloud is not installed. See https://cloud.google.com/sdk/docs/install'
if ! gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | grep -q .; then
  die 'No active account. Run: gcloud auth login'
fi

if (($# == 0)); then
  project=$(gcloud config get-value project 2>/dev/null) || project=""
  if [[ -z "$project" || "$project" == "(unset)" ]]; then
    printf 'ℹ️  No active project. Run: gcp-project my-project-id\n' >&2
    exit 1
  fi
  printf '📦 %s\n' "$project"
  exit 0
fi

project="$1"
if ! printf '%s\n' "$project" | grep -Eq '^[a-z][a-z0-9-]{4,28}[a-z0-9]$'; then
  die "That does not look like a project ID: $project"
fi

if ! gcloud config set project "$project" >/dev/null; then
  die 'Could not set the project. Check the ID and your access.'
fi
printf '✅ Active project is now %s\n' "$project"
