#!/usr/bin/env bash
# Show or set the default AWS region.
# Usage: aws-region [REGION]
# Needs: aws

set -euo pipefail

usage() {
  cat << 'EOF'
Usage: aws-region [REGION]

With no argument, print the default region from your AWS profile.
With a region, save it as the default. A profile option is not needed.

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
(($# <= 1)) || die 'Pass one region only.'

command -v aws > /dev/null 2>&1 \
  || die 'aws is not installed. See https://aws.amazon.com/cli/'

if (($# == 0)); then
  region=$(aws configure get region 2> /dev/null) || region=""
  if [[ -z "$region" ]]; then
    printf 'ℹ️  No default region is set. Run: aws-region eu-west-1\n' >&2
    exit 1
  fi
  printf '🌍 %s\n' "$region"
  exit 0
fi

region="$1"
if ! printf '%s\n' "$region" | grep -Eq '^[a-z]{2}(-[a-z]+)+-[0-9]+$'; then
  die "That does not look like a region name: $region"
fi

if ! aws configure set region "$region"; then
  die 'Could not save the region. Check the AWS config file.'
fi
printf '✅ Default region is now %s\n' "$region"
