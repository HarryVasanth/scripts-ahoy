#!/usr/bin/env bash
# List the keys in Kubernetes secrets. Values are never shown.
# Usage: k8s-secret-keys [--namespace NS] [SECRET]
# Needs: kubectl

set -euo pipefail

usage() {
  cat << 'EOF'
Usage: k8s-secret-keys [--namespace NS] [SECRET]

Print the key names in one secret, or in every secret in the namespace.
The decoded values are never printed.

  --namespace NS  Read this namespace. The default is the active one.
  -h, --help      Show this help.
EOF
}

die() {
  printf '❌ %s\n' "$1" >&2
  exit 1
}

ns=""
name=""
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
    -*) die "Unknown option: $1" ;;
    *)
      [[ -z "$name" ]] || die 'Pass one secret only.'
      name="$1"
      ;;
  esac
  shift
done

command -v kubectl > /dev/null 2>&1 \
  || die 'kubectl is not installed. See https://kubernetes.io/docs/tasks/tools/'

# shellcheck disable=SC2016  # Go template syntax, not shell expansion.
template='{{range $k, $v := .data}}{{$k}}{{"\n"}}{{end}}'
keys_of() {
  if [[ -n "$ns" ]]; then
    kubectl get secret "$1" -n "$ns" -o go-template="$template"
  else
    kubectl get secret "$1" -o go-template="$template"
  fi
}

if [[ -n "$name" ]]; then
  keys_of "$name" || die "Cannot read secret $name. Check the name and namespace."
  exit 0
fi

if [[ -n "$ns" ]]; then
  list=$(kubectl get secrets -n "$ns" -o name 2> /dev/null) \
    || die "Cannot list secrets in $ns. Check the name and your credentials."
else
  list=$(kubectl get secrets -o name 2> /dev/null) \
    || die 'Cannot list secrets. Check your kubeconfig and credentials.'
fi

[[ -n "$list" ]] || {
  printf 'ℹ️  No secrets found. ✅\n'
  exit 0
}

if [[ -n "$ns" ]]; then printf '🔑 Secret keys in namespace %s:\n' "$ns"; else printf '🔑 Secret keys:\n'; fi

while IFS= read -r item; do
  [[ -n "$item" ]] || continue
  secret=${item#secret/}
  printf '\n%s\n' "$secret"
  keys_of "$secret" | sed 's/^/  /'
done <<< "$list"
