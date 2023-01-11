#!/bin/bash

# Pull every repository listed in a text file.
# Usage: ./pull.sh FILE
#
# FILE contains one repository path per line (see ../bash/list_example.txt).

git_pull() {
  git pull --recurse-submodules --rebase
}

if (($# < 1)); then
  echo "There must be 1 argument - file with repositories' list"
  exit
fi

LISTFILE="$1"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

export -f git_pull
bash "$DIR/../bash/parse_filelist.sh" "$LISTFILE" git_pull "Updating repository"
