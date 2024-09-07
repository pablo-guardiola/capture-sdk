#!/bin/bash

# Checks whether the files in provided regex via the command line has changed when comparing the HEAD ref and
# $GITHUB_BASE_REF, i.e. the target branch (usually main). Returns true if the current branch is main.
#
# Usage: ./ci/files_changed.sh <regex>

set -e

# Trap to handle unexpected errors and log them
trap 'echo "An unexpected error occurred during file change check."; exit 1' ERR

echo "DEBUG: Starting files_changed.sh"
echo "DEBUG: Current directory: $(pwd)"
echo "DEBUG: Current branch: $(git rev-parse --abbrev-ref HEAD)"
echo "DEBUG: GITHUB_BASE_REF: $GITHUB_BASE_REF"
echo "DEBUG: Remote repositories: $(git remote -v)"

# Check for file changes
if git rev-parse --abbrev-ref HEAD | grep -q ^main$ || git diff --name-only "origin/$GITHUB_BASE_REF" | grep -E "$1" ; then
  echo "Relevant file changes detected!"
  exit 0  # Relevant changes detected
else
  echo "No relevant changes found."
  exit 2  # No relevant changes found (but no error)
fi
