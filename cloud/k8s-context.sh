#!/usr/bin/env bash
# List, show or switch kubectl contexts.
# Usage: k8s-context [--current] [CONTEXT]
# Needs: kubectl

set -euo pipefail

usage() {
  cat << 'EOF'
Usage: k8s-context [--current] [CONTEXT]

With no argument, list every context. With a name, switch to it.
The * marks the active context in the list.

  --current   Print the active context only.
  -h, --help  Show this help.
EOF
}

current=0
context=""

while (($# > 0)); do
  case "$1" in
    --current) current=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      printf '❌ Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -n "$context" ]]; then
        printf '❌ Pass one context only.\n' >&2
        exit 1
      fi
      context="$1"
      ;;
  esac
  shift
done

if ! command -v kubectl > /dev/null 2>&1; then
  printf '❌ kubectl is not installed. Install it: https://kubernetes.io/docs/tasks/tools/\n' >&2
  exit 1
fi

if ((current == 1)); then
  if ! kubectl config current-context 2> /dev/null; then
    printf '❌ No context is set. Run: kubectl config use-context NAME\n' >&2
    exit 1
  fi
  exit 0
fi

if [[ -z "$context" ]]; then
  names=$(kubectl config get-contexts -o name 2> /dev/null || true)
  if [[ -z "$names" ]]; then
    printf 'ℹ️  No contexts found. Set KUBECONFIG, or add a cluster with kubectl config.\n' >&2
    exit 0
  fi
  kubectl config get-contexts
  exit 0
fi

if ! kubectl config get-contexts -o name 2> /dev/null | grep -Fxq "$context"; then
  printf '❌ Unknown context: %s\n' "$context" >&2
  printf '   Known contexts:\n' >&2
  kubectl config get-contexts -o name 2> /dev/null | sed 's/^/   /' >&2
  exit 1
fi

if ! kubectl config use-context "$context" > /dev/null; then
  printf '❌ Could not switch context. Check the kubeconfig file.\n' >&2
  exit 1
fi

printf '✅ Now using context %s\n' "$context"
