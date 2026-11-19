#!/usr/bin/env bash
# Show recent warning events in the cluster.
# Usage: k8s-events [--tail N] [--namespace NS]
# Needs: kubectl
# Since: 2017-03

set -euo pipefail

usage() {
  cat << 'EOF'
Usage: k8s-events [--tail N] [--namespace NS]

Print warning events, newest first. With no namespace, read all namespaces.

  --tail N         Show at most N events. The default is 25.
  --namespace NS   Read one namespace only.
  -h, --help       Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

tail="25"
ns=""
while (($# > 0)); do
  case "$1" in
    --tail)
      shift
      (($# > 0)) || die 'Option --tail needs a count.'
      tail="$1"
      ;;
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
case "$tail" in
  '' | *[!0-9]*) die "The tail count must be a number: $tail" ;;
esac

command -v kubectl > /dev/null 2>&1 \
  || die 'kubectl is not installed. See https://kubernetes.io/docs/tasks/tools/'

if [[ -n "$ns" ]]; then
  events=$(kubectl get events -n "$ns" --field-selector type=Warning \
    --sort-by=.lastTimestamp 2>&1) \
    || die "Cannot read namespace $ns. Check the name and your credentials."
else
  events=$(kubectl get events --all-namespaces --field-selector type=Warning \
    --sort-by=.lastTimestamp 2>&1) \
    || die 'Cannot read events. Check "kubectl config current-context".'
fi

if [[ -z "$events" ]]; then
  printf '✅ No warning events.\n'
  exit 0
fi

printf '⚠️  Most recent warning events (up to %s):\n\n' "$tail"
printf '%s\n' "$events" | tail -n "$tail"
