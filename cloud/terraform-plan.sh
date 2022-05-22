#!/usr/bin/env bash
# Run terraform init and plan, and save the plan file.
# Usage: terraform-plan [--out FILE] [DIR]
# Needs: terraform

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: terraform-plan [--out FILE] [DIR]

Run terraform init, then terraform plan in DIR, and save the plan.
The default directory is the current one and the default file is tfplan.

  --out FILE  Save the plan as FILE.
  -h, --help  Show this help.
EOF
}

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

out="tfplan"
dir="."
while (($# > 0)); do
  case "$1" in
    --out) shift; (($# > 0)) || die 'Option --out needs a file.'; out="$1" ;;
    -h|--help) usage; exit 0 ;;
    -*) die "Unknown option: $1" ;;
    *) dir="$1" ;;
  esac
  shift
done

[[ -d "$dir" ]] || die "Directory not found: $dir"
command -v terraform >/dev/null 2>&1 ||
  die 'terraform is not installed. See https://developer.hashicorp.com/terraform/install'

cd "$dir"

printf '⚙️  terraform init\n'
terraform init -input=false || die 'terraform init failed. Read the errors above.'

printf '📝 terraform plan\n'
terraform plan -input=false -out="$out" ||
  die 'terraform plan failed. Nothing was applied.'

printf '\n✅ Plan saved to %s/%s\n' "$(pwd)" "$out"
printf '👉 Review it with: terraform show %s\n' "$out"
