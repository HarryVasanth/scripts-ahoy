#!/usr/bin/env bash
# Print the total size of an S3 bucket or prefix.
# Usage: aws-s3-size <s3://bucket[/prefix]>
# Needs: aws

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: aws-s3-size <s3://bucket[/prefix]>

List every object under the target and print the total count and size.
The size is the stored size, before any transfer.

  -h, --help  Show this help.
EOF
}

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  "") usage >&2; die 'Pass an S3 path, for example s3://my-bucket/reports/' ;;
  -*) die "Unknown option: $1" ;;
esac
(($# == 1)) || die 'Pass one S3 path only.'
target="${1%/}"
case "$target" in
  s3://*) ;;
  *) die "The path must start with s3://, got: $target" ;;
esac

command -v aws >/dev/null 2>&1 ||
  die 'aws is not installed. See https://aws.amazon.com/cli/'
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  die 'No AWS session. Run "aws configure", or refresh your SSO login.'
fi

printf '🪣 %s\n' "$target"
if ! result=$(aws s3 ls "$target" --recursive --summarize --human-readable 2>&1); then
  printf '❌ Could not list %s\n' "$target" >&2
  printf '%s\n' "$result" >&2
  exit 1
fi

count=$(printf '%s\n' "$result" | sed -n 's/^Total Objects:[[:space:]]*//p')
size=$(printf '%s\n' "$result" | sed -n 's/^Total Size:[[:space:]]*//p')
if [[ -z "$count" ]]; then
  printf 'ℹ️  No objects under this path.\n'
  exit 0
fi

printf '📦 Objects: %s\n' "$count"
printf '💾 Total size: %s\n' "$size"
