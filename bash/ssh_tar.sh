#!/usr/bin/env bash

# Copy a folder over SSH with tar. This is faster than a plain recursive copy for many small files.
# The first arguments go to ssh (user, host, port and so on). The last argument is the remote folder.
# Usage: ./ssh_tar.sh user@host /path/to/folder
#        ./ssh_tar.sh user@host -p 2222 /path/to/folder

set -euo pipefail

if (($# < 2)); then
  printf 'Usage: %s <ssh args...> <remote directory>\n' "$0" >&2
  exit 1
fi

LAST_ARG="${!#}"
BASENAME=$(basename "$LAST_ARG")
DIRNAME=$(dirname "$LAST_ARG")
COUNT=$#
ARGS=("$@")
unset "ARGS[$((COUNT - 1))]"

# shellcheck disable=SC2029  # The remote path is quoted with printf %q before it reaches the shell.
ssh "${ARGS[@]}" "cd $(printf '%q' "$DIRNAME"); tar zcf - $(printf '%q' "$BASENAME")" | tar zxf -
