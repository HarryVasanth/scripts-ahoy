#!/usr/bin/env bash
# Sync a local path to S3. It is a dry run unless you pass --apply.
# Usage: s3-sync [--apply] [--delete] [--exclude GLOB] [--yes] SOURCE s3://BUCKET/PREFIX
# Needs: aws
# Note: --delete removes objects in the target that are not in the source.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: s3-sync [--apply] [--delete] [--exclude GLOB] [--yes] SOURCE TARGET

Copy a directory or file to S3 with aws s3 sync.
The default is a dry run, so you can read the plan first.

  --apply         Copy the files.
  --delete        Remove target objects that are missing from the source.
                  This needs --apply.
  --exclude GLOB  Skip files that match the pattern. Repeatable.
  --yes           Skip the confirmation prompt.
  -h, --help      Show this help.
EOF
}

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

apply=0
delete=0
yes=0
excludes=()
args=()
while (($# > 0)); do
  case "$1" in
    --apply) apply=1 ;;
    --delete) delete=1 ;;
    --yes) yes=1 ;;
    --exclude)
      (($# > 1)) || die '--exclude needs a pattern.'
      excludes+=("$2")
      shift ;;
    -h|--help) usage; exit 0 ;;
    -*) die "Unknown option: $1" ;;
    *) args+=("$1") ;;
  esac
  shift
done

((${#args[@]} == 2)) || { usage >&2; die 'Pass a source and an s3:// target.'; }
src="${args[0]}"
dst="${args[1]}"
[[ -e "$src" ]] || die "Source not found: $src"
[[ "$dst" == s3://* ]] || die 'The target must start with s3://'
if ((delete == 1 && apply == 0)); then die '--delete needs --apply. Nothing was changed.'; fi
command -v aws >/dev/null 2>&1 || die 'aws is not installed. Install the AWS CLI: https://docs.aws.amazon.com/cli/'
aws sts get-caller-identity >/dev/null 2>&1 ||
  die 'The AWS session is missing or expired. Run: aws sso login (or aws configure for static keys)'

flags=()
if ((apply == 0)); then
  flags+=(--dryrun)
elif ((delete == 1)); then
  flags+=(--delete)
fi
for pattern in ${excludes[@]+"${excludes[@]}"}; do
  flags+=(--exclude "$pattern")
done

if ((apply == 1)); then
  printf '📤 Sync %s → %s\n' "$src" "$dst" >&2
  if ((delete == 1)); then
    printf '⚠️  Objects in the target that are missing from the source will be removed.\n' >&2
  fi
  if ((yes == 0)); then
    read -r -p 'Continue? [y/N] ' reply
    [[ "$reply" =~ ^[Yy]$ ]] || { printf '👋 Nothing was copied.\n' >&2; exit 0; }
  fi
else
  printf '🔍 Dry run. Add --apply to copy the files.\n' >&2
fi

aws s3 sync "$src" "$dst" "${flags[@]}"
