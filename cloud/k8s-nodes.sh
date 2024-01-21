#!/usr/bin/env bash
# Show node status and capacity.
# Usage: k8s-nodes
# Needs: kubectl
# Since: 2016-12

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: k8s-nodes

Print each node with its Ready state and allocatable CPU, memory
and pod capacity. The columns come from the node status.

  -h, --help  Show this help.
EOF
}

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  -*) die "Unknown option: $1" ;;
esac
(($# == 0)) || die 'This script takes no arguments.'

command -v kubectl >/dev/null 2>&1 ||
  die 'kubectl is not installed. See https://kubernetes.io/docs/tasks/tools/'
if ! kubectl cluster-info >/dev/null 2>&1; then
  die 'Cannot reach the cluster. Check "kubectl config current-context" and your credentials.'
fi

kubectl get nodes -o custom-columns='NAME:.metadata.name,READY:.status.conditions[?(@.type=="Ready")].status,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory,PODS:.status.capacity.pods'

printf '\nℹ️  Capacity is the limit. Use "kubectl top nodes" for live use.\n' >&2
