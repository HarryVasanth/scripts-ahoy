#!/bin/bash

# Rewrite the author name and email in every commit, branch, and tag.
# Usage: ./change_author.sh OLD_EMAIL NEW_NAME NEW_EMAIL
#
# Original from https://stackoverflow.com/a/750182.
# Run this script from the folder that holds the repository.
# WARNING! These changes are dangerous because they change git history!
# $1 - wrong email
# $2 - correct name
# $3 - correct email

if (($# < 3)); then
  echo "There must be 3 arguments - old (wrong) email, new (correct) name and new (correct) email"
  exit
fi

OLD_EMAIL="$1"
CORRECT_NAME="$2"
CORRECT_EMAIL="$3"

git filter-branch --env-filter "
if [ \$GIT_COMMITTER_EMAIL = $OLD_EMAIL ]
then
    export GIT_COMMITTER_NAME=$CORRECT_NAME
    export GIT_COMMITTER_EMAIL=$CORRECT_EMAIL
fi
if [ \$GIT_AUTHOR_EMAIL = $OLD_EMAIL ]
then
    export GIT_AUTHOR_NAME=$CORRECT_NAME
    export GIT_AUTHOR_EMAIL=$CORRECT_EMAIL
fi
" --tag-name-filter cat -- --branches --tags
