#!/bin/bash

# Count words and lines in files of one or more types.
# Usage: ./wc.sh DIR EXT [EXT...]
#
# DIR is the directory to search.
# EXT lists the file extensions to include.

if (($# < 2)); then
  echo "There must be at least 2 arguments - directory and file extensions to count"
  exit
fi

DIR=$1
shift
TYPES=(-name "*.$1")
shift
for ext in "$@"; do
  TYPES+=(-or -name \*."$ext")
done
find "$DIR" -type f \( "${TYPES[@]}" \) -exec wc {} +
