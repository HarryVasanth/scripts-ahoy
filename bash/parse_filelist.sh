#!/bin/bash

# Call a command for each directory listed in a text file.
# Usage: ./parse_filelist.sh FILE COMMAND TEXT
#
# FILE is a file containing a list of repositories (see list_example.txt).
# COMMAND is the command or function to call for each directory.
# TEXT is shown before each directory.

if (($# < 3)); then
  echo "There must be 3 arguments - file list, function or command to do and text"
  exit
fi

LISTFILE="$1"
CMD="$2"
TEXT="$3"

while read -r line || [ -n "$line" ]; do
  [[ -z "$line" ]] && continue # ignore empty lines
  pushd "$PWD" > /dev/null || exit
  cd "${line/#~/$HOME}" || { popd && continue; }
  echo "$TEXT $line"
  $CMD
  popd > /dev/null || exit
done < "$LISTFILE"
