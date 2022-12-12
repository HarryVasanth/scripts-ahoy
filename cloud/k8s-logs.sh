#!/usr/bin/env bash
# Follow logs for one pod or for pods that match a label.
# Usage: k8s-logs [-n NS] [-p POD | -l SELECTOR] [-c CONTAINER] [--since DUR] [--tail N] [--previous]
# Needs: kubectl
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: k8s-logs [-n NS] [-p POD | -l SELECTOR] [-c CONTAINER]
                [--since DUR] [--tail N] [--previous]

Follow the logs of a pod, or of the pods that match a label selector.
Pass either -p or -l.

  -n, --namespace NS   Namespace. Default: the context namespace.
  -p, --pod POD        Pod name.
  -l, --selector SEL   Label selector, for example app=web.
  -c, --container NAME Container name.
  --since DUR          Show logs since the duration, for example 10m.
  --tail N             Show the last N lines first.
  --previous           Show the logs of the previous container run.
  -h, --help           Show this help.
EOF
}

die() { printf '❌ %s\n' "$1" >&2; exit 1; }

namespace=""
pod=""
selector=""
container=""
since=""
tail=""
previous=0
while (($# > 0)); do
  case "$1" in
    -n|--namespace|-p|--pod|-l|--selector|-c|--container|--since|--tail)
      (($# > 1)) || die "$1 needs a value."
      case "$1" in
        -n|--namespace) namespace="$2" ;;
        -p|--pod) pod="$2" ;;
        -l|--selector) selector="$2" ;;
        -c|--container) container="$2" ;;
        --since) since="$2" ;;
        --tail) tail="$2" ;;
      esac
      shift ;;
    --previous) previous=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

if [[ -z "$pod" && -z "$selector" ]]; then die 'Pass a pod with -p, or a selector with -l.'; fi
if [[ -n "$pod" && -n "$selector" ]]; then die 'Pass a pod or a selector, not both.'; fi
if [[ -n "$tail" && ! "$tail" =~ ^[0-9]+$ ]]; then die '--tail needs a number.'; fi

command -v kubectl >/dev/null 2>&1 || die 'kubectl is not installed. Install it: https://kubernetes.io/docs/tasks/tools/'
kubectl config current-context >/dev/null 2>&1 || die 'No kubectl context is set. Run: kubectl config use-context NAME'

cmd=(kubectl logs -f)
[[ -z "$namespace" ]] || cmd+=(-n "$namespace")
if [[ -n "$selector" ]]; then cmd+=(-l "$selector"); else cmd+=("$pod"); fi
[[ -z "$container" ]] || cmd+=(-c "$container")
[[ -z "$since" ]] || cmd+=(--since "$since")
[[ -z "$tail" ]] || cmd+=(--tail "$tail")
((previous == 0)) || cmd+=(--previous)

"${cmd[@]}"
