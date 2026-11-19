#!/usr/bin/env bash
# Report IAM users without MFA and access keys older than 90 days.
# Usage: aws-iam-audit
# Needs: aws

set -euo pipefail

usage() {
  cat << 'EOF'
Usage: aws-iam-audit

List users that have no MFA device, and access keys older than 90 days.
Key secrets are never read or printed.

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
esac
(($# == 0)) || die "Unexpected argument: $1"

command -v aws > /dev/null 2>&1 \
  || die 'aws is not installed. See https://aws.amazon.com/cli/'
if ! aws sts get-caller-identity > /dev/null 2>&1; then
  die 'No AWS session. Run "aws configure", or refresh your SSO login.'
fi

users=$(aws iam list-users --query 'Users[].UserName' --output text 2> /dev/null) \
  || die 'Cannot read IAM users. Check your permissions.'
if [[ -z "$users" || "$users" == "None" ]]; then
  printf 'ℹ️  No IAM users in this account.\n'
  exit 0
fi

age_days() {
  stamp=${1%%+*}
  stamp=${stamp%Z}
  when=$(date -u -d "$stamp" +%s 2> /dev/null \
    || date -j -f "%Y-%m-%dT%H:%M:%S" "$stamp" +%s 2> /dev/null || printf 0)
  printf '%s' $(((now - when) / 86400))
}

now=$(date -u +%s)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/aws-iam-audit.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
: > "$tmp/no_mfa"
: > "$tmp/keys"

while IFS= read -r user; do
  mfa=$(aws iam list-mfa-devices --user-name "$user" --query 'MFADevices[]' --output text 2> /dev/null) || mfa=""
  [[ -n "$mfa" ]] || printf '%s\n' "$user" >> "$tmp/no_mfa"
  keys=$(aws iam list-access-keys --user-name "$user" \
    --query 'AccessKeyMetadata[].[AccessKeyId,Status,CreateDate]' --output text 2> /dev/null) || keys=""
  while read -r key_id status created; do
    [[ -n "$key_id" ]] || continue
    age=$(age_days "$created")
    if ((age > 90)); then
      printf '%-20s %-22s %-8s %s days\n' "$user" "$key_id" "$status" "$age" >> "$tmp/keys"
    fi
  done <<< "$keys"
done < <(printf '%s\n' "$users" | tr '\t' '\n')

show() { if [[ -s "$1" ]]; then sed 's/^/  /' "$1"; else printf '  none ✅\n'; fi; }
printf '🔐 Users without MFA:\n'
show "$tmp/no_mfa"
printf '\n🗓️  Access keys older than 90 days:\n'
show "$tmp/keys"
