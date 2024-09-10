#!/bin/bash

# Checks whether the files in provided regex via the command line has changed when comparing the HEAD ref and
# $GITHUB_BASE_REF, i.e. the target branch (usually main). Returns true if the current branch is main.
#
# Usage: ./ci/files_changed.sh <regex>

set -euo pipefail

# Trap to handle unexpected errors and log them
trap 'echo "An unexpected error occurred during file change check."; echo "check_result=1" >> "$GITHUB_OUTPUT"; exit 1' ERR

# Determine the base ref or fallback to HEAD when running on main
# TODO uncomment this is a test for trap
#if [[ -z "${GITHUB_BASE_REF:-}" ]]; then
#  echo "GITHUB_BASE_REF is empty, likely running on main branch. Using HEAD~1 for comparison."
#  base_ref="HEAD"
#else
#  git fetch origin "$GITHUB_BASE_REF":"$GITHUB_BASE_REF"
#  base_ref="origin/$GITHUB_BASE_REF"
#fi


# Check if current branch is main
is_main_branch=false
if git rev-parse --abbrev-ref HEAD | grep -q ^main$; then
  is_main_branch=true
fi


# Check for file changes using the base ref
changes_detected=false
if $is_main_branch || git diff --name-only "origin/$GITHUB_BASE_REF" | grep -E "$1"; then
  changes_detected=true
fi

# Check for file changes
if [ "$changes_detected" = true ]; then
  echo "Relevant file changes detected!"
  echo "check_result=0" >> "$GITHUB_OUTPUT"
  exit 0  # Relevant changes detected
else
  echo "No relevant changes found."
  echo "check_result=2" >> "$GITHUB_OUTPUT"
fi
