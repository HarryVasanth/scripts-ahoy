#!/usr/bin/env bash
# List GCS buckets with their creation dates.
# Usage: gcp-bucket-list
# Needs: gsutil (Google Cloud SDK)

set -euo pipefail

usage() {
  cat << 'EOF'
Usage: gcp-bucket-list

List every bucket in the active project and show when it was created.
Change the project with gcp-project or "gcloud config set project".

  -h, --help  Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  -*) die "Unknown option: $1" ;;
esac
(($# == 0)) || die 'This script takes no arguments.'

command -v gsutil > /dev/null 2>&1 \
  || die 'gsutil is not installed. Install the Google Cloud SDK first.'
if ! gsutil ls -b 'gs://*' > /dev/null 2>&1; then
  die 'Cannot list buckets. Run "gcloud auth login" and set a project.'
fi

result=$(gsutil ls -L -b 'gs://*' 2> /dev/null) \
  || die 'gsutil failed. Check your network and permissions.'

if [[ -z "$result" ]]; then
  printf 'ℹ️  No buckets in this project.\n'
  exit 0
fi

printf '🪣 Buckets:\n'
printf '%s\n' "$result" | awk '
  /^gs:\/\// {
    bucket = $1
    sub(/\/$/, "", bucket)
    next
  }
  /Time created:/ {
    sub(/^.*Time created:[ \t]*/, "")
    printf "  %-45s %s\n", bucket, $0
  }
'
