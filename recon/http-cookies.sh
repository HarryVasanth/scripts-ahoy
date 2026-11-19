#!/usr/bin/env bash
set -euo pipefail

# Inspect the Set-Cookie flags on a URL.
# Usage: http-cookies.sh <url>
# Needs: curl

usage() {
  printf 'Usage: %s <url>\nExample: %s https://example.com\n' "${0##*/}" "${0##*/}"
}
if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi
if [[ $# -lt 1 || -z ${1:-} ]]; then
  usage >&2
  exit 1
fi
command -v curl > /dev/null 2>&1 || {
  printf 'Error: curl is not installed.\n' >&2
  exit 1
}

url=$1
case "$url" in
  http://* | https://*) ;;
  *)
    printf 'Error: give a URL that starts with http:// or https://.\n' >&2
    exit 1
    ;;
esac

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
if ! code=$(curl -sS -L --max-time 15 -D "$tmp" -o /dev/null -w '%{http_code}' "$url"); then
  printf 'Error: cannot reach "%s".\n' "$url" >&2
  exit 1
fi

printf '🍪 Cookies from %s (HTTP %s)\n' "$url" "$code"
found=0
while IFS= read -r line; do
  line=${line#*:}
  line=${line# }
  line=${line%$'\r'}
  [[ -n $line ]] || continue
  found=$((found + 1))
  name=${line%%=*}
  printf '   %s\n' "$name"
  lower=$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')

  flags=""
  case "; $lower" in *'; secure'*) flags="$flags Secure" ;; esac
  case "; $lower" in *'; httponly'*) flags="$flags HttpOnly" ;; esac
  same=$(printf '%s' "$line" | sed -n 's/.*[Ss]ame[Ss]ite=\([^;]*\).*/\1/p')
  [[ -z $same ]] || flags="$flags SameSite=$same"
  printf '      Flags:%s\n' "${flags:- none}"

  case "; $lower" in
    *'; max-age='* | *'; expires='*) printf '      Type:  persistent\n' ;;
    *) printf '      Type:  session\n' ;;
  esac
  case "; $lower" in *'; secure'*) ;; *) printf '      ⚠️  No Secure flag.\n' ;; esac
  case "; $lower" in *'; httponly'*) ;; *) printf '      ⚠️  No HttpOnly flag.\n' ;; esac
  same_lc=$(printf '%s' "$same" | tr '[:upper:]' '[:lower:]')
  if [[ -z $same ]]; then
    printf '      ⚠️  No SameSite flag.\n'
  elif [[ $same_lc == none ]]; then
    case "; $lower" in *'; secure'*) ;; *) printf '      ⚠️  SameSite=None needs Secure.\n' ;; esac
  fi
done < <(grep -i '^set-cookie:' "$tmp" || true)

if ((found == 0)); then
  printf '   No Set-Cookie headers on this response.\n'
  exit 1
fi
printf '📊 %d cookie(s).\n' "$found"
