#!/usr/bin/env bash
# Print Markdown badges for a GitHub repository.
# Usage: readme-badges --repo OWNER/NAME [--license ID] [--workflow FILE] [--branch NAME] [--tag VERSION]
set -euo pipefail

usage() {
  cat << 'EOF'
Usage: readme-badges --repo OWNER/NAME [options]

Print one Markdown line with the badges that you ask for.

  --repo OWNER/NAME  Repository. Required.
  --license ID       Static licence badge, for example MIT.
  --workflow FILE    GitHub Actions workflow status.
  --branch NAME      Branch for the workflow badge. Default: main.
  --tag VERSION      Static version badge.
  -h, --help         Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

repo=""
license=""
workflow=""
branch="main"
tag=""
while (($# > 0)); do
  case "$1" in
    --repo | --license | --workflow | --branch | --tag)
      (($# > 1)) || die "$1 needs a value."
      case "$1" in
        --repo) repo="$2" ;;
        --license) license="$2" ;;
        --workflow) workflow="$2" ;;
        --branch) branch="$2" ;;
        --tag) tag="$2" ;;
      esac
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

[[ -n "$repo" ]] || die '--repo is required.'
[[ "$repo" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || die "Use the form OWNER/NAME: $repo"

badges=""
if [[ -n "$workflow" ]]; then
  badge=$(printf '[![CI](https://img.shields.io/github/actions/workflow/status/%s/%s?branch=%s&style=flat-square&label=CI)](https://github.com/%s/actions)' \
    "$repo" "$workflow" "$branch" "$repo")
  badges="$badges$badge "
fi

if [[ -n "$license" ]]; then
  badge=$(printf '[![Licence](https://img.shields.io/badge/licence-%s-blue?style=flat-square)](https://github.com/%s)' \
    "${license//-/--}" "$repo")
  badges="$badges$badge "
fi

if [[ -n "$tag" ]]; then
  badge=$(printf '[![Version](https://img.shields.io/badge/version-%s-blue?style=flat-square)](https://github.com/%s/releases)' \
    "$tag" "$repo")
  badges="$badges$badge "
fi

[[ -n "$badges" ]] || die 'Nothing to show. Pass --license, --workflow or --tag.'
printf '%s\n' "${badges% }"
printf 'ℹ️  Paste the line under the title in README.md.\n' >&2
