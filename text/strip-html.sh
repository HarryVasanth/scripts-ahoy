#!/usr/bin/env bash
# Remove HTML tags and decode common entities.
# Usage: strip-html.sh [FILE...]

set -euo pipefail

case "${1:-}" in
  -h | --help)
    cat << 'EOF'
Turn a simple HTML page into plain text.
Usage: strip-html.sh [FILE...]

Reads standard input when no FILE is given.
Tags are removed and these entities are decoded:
&amp; &lt; &gt; &quot; &apos; &#39; &nbsp;

The script works line by line. A tag split over two lines is not removed.
EOF
    exit 0
    ;;
  -*)
    printf 'error: unknown option %s\n' "$1" >&2
    exit 1
    ;;
esac

for f in "$@"; do
  [[ -r "$f" ]] || {
    printf 'error: cannot read %s\n' "$f" >&2
    exit 1
  }
done

sed \
  -e 's/<[^>]*>//g' \
  -e 's/&nbsp;/ /g' \
  -e 's/&lt;/</g' \
  -e 's/&gt;/>/g' \
  -e 's/&quot;/"/g' \
  -e "s/&#39;/'/g" \
  -e "s/&apos;/'/g" \
  -e 's/&amp;/\&/g' \
  "$@"
