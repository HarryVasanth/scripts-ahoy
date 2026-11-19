#!/usr/bin/env bash
# Show this month's AWS cost, grouped by service.
# Usage: aws-cost [--top N]
# Needs: aws, jq
set -euo pipefail

usage() {
  cat << 'EOF'
Usage: aws-cost [--top N]

Print the month-to-date spend, then the largest services.
The cost comes from the AWS Cost Explorer API.

  --top N     Show the N largest services. Default: 10.
  -h, --help  Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

top=10
while (($# > 0)); do
  case "$1" in
    --top)
      (($# > 1)) || die '--top needs a number.'
      top="$2"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

if ! [[ "$top" =~ ^[0-9]+$ ]] || ! ((10#$top > 0)); then
  die '--top must be a positive number.'
fi
top=$((10#$top))

command -v aws > /dev/null 2>&1 || die 'aws is not installed. Install the AWS CLI: https://docs.aws.amazon.com/cli/'
command -v jq > /dev/null 2>&1 || die 'jq is not installed. Install it: https://jqlang.github.io/jq/'
aws sts get-caller-identity > /dev/null 2>&1 \
  || die 'The AWS session is missing or expired. Run: aws sso login (or aws configure for static keys)'

start=$(date +%Y-%m-01)
end=$(date -d tomorrow +%Y-%m-%d 2> /dev/null) || end=$(date -v+1d +%Y-%m-%d)

if ! raw=$(aws ce get-cost-and-usage \
  --time-period "Start=$start,End=$end" \
  --granularity MONTHLY --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE --output json 2>&1); then
  printf '❌ The cost request failed.\n%s\n' "$raw" >&2
  exit 1
fi

unit=$(printf '%s' "$raw" | jq -r '[.ResultsByTime[].Total.UnblendedCost.Unit][0] // "USD"')
total=$(printf '%s' "$raw" | jq -r '[.ResultsByTime[].Total.UnblendedCost.Amount | tonumber] | add // 0')
total_fmt=$(printf '%s' "$total" | awk '{ printf "%.2f", $1 }')

printf '💰 AWS spend for %s to %s: %s %s\n' "$start" "$(date +%Y-%m-%d)" "$total_fmt" "$unit"
if [[ "$total_fmt" == '0.00' ]]; then
  printf '🎉 No spend recorded so far.\n'
  exit 0
fi

printf '\nTop %s services:\n' "$top"
printf '%s' "$raw" | jq -r '.ResultsByTime[].Groups[]
  | [((.Metrics.UnblendedCost.Amount | tonumber) * 100 | round / 100), .Keys[0]] | @tsv' \
  | sort -rn | head -n "$top" | awk -F '\t' '{ printf "   %9.2f  %s\n", $1, $2 }'
