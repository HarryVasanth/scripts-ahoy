#!/bin/bash

# Push the current repository, or a list of repositories, to every remote.
# Usage: ./push.sh [FILE]
#
# With no FILE, it pushes the current folder. FILE holds one path per line
# (see ../bash/list_example.txt).

git_push_to_all_remotes() {
  for origin in $(git remote); do
    git push --all "$origin"
  done
}

if (($# == 0)); then
  git_push_to_all_remotes
  exit
fi

LISTFILE="$1"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

export -f git_push_to_all_remotes
bash "$DIR/../bash/parse_filelist.sh" "$LISTFILE" git_push_to_all_remotes "Pushing repository"
