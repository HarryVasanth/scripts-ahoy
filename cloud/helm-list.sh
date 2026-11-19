#!/usr/bin/env bash
# List Helm releases across namespaces.
# Usage: helm-list [--namespace NS]
# Needs: helm 3
# Since: 2019-11

set -euo pipefail

usage() {
  cat << 'EOF'
Usage: helm-list [--namespace NS]

List releases with their namespace, revision and status.
With no namespace, show every namespace.

  --namespace NS  Show one namespace only.
  -h, --help      Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

ns=""
while (($# > 0)); do
  case "$1" in
    --namespace | -n)
      shift
      (($# > 0)) || die 'Option --namespace needs a name.'
      ns="$1"
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "Unknown argument: $1" ;;
  esac
  shift
done

command -v helm > /dev/null 2>&1 \
  || die 'helm is not installed. See https://helm.sh/docs/intro/install/'

if [[ -n "$ns" ]]; then
  helm list --namespace "$ns" \
    || die "helm list failed for namespace $ns. Check the name and your kubeconfig."
else
  helm list --all-namespaces \
    || die 'helm list failed. Check your kubeconfig, or install Helm 3.'
fi
