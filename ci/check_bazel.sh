#!/bin/bash

set -euo pipefail

echo "DEBUG: Starting check_bazel.sh"
echo "DEBUG: Current directory: $(pwd)"
echo "DEBUG: GITHUB_BASE_REF: $GITHUB_BASE_REF"
echo "DEBUG: GITHUB_HEAD_REF: $GITHUB_HEAD_REF"
echo "DEBUG: Remote repositories: $(git remote -v)"

# Ensure we fetch the base branch (main) to make it available
git fetch origin "$GITHUB_BASE_REF":"$GITHUB_BASE_REF"

# Get the latest commit SHA for the base branch (target branch of the PR)
base_sha=$(git rev-parse "$GITHUB_BASE_REF")
# Get the latest commit SHA for the PR branch (the head ref in the forked repository)
final_revision=$GITHUB_SHA

# Use git merge-base to find the common ancestor of the two commits
previous_revision=$(git merge-base "$base_sha" "$final_revision")

echo "DEBUG: Base SHA: $base_sha"
echo "DEBUG: Final Revision (Head SHA): $final_revision"
echo "DEBUG: Previous Revision (Merge Base): $previous_revision"

# Path to your Bazel WORKSPACE directory
workspace_path=$(pwd)
# Path to your Bazel executable
bazel_path=$(pwd)/bazelw

starting_hashes_json="/tmp/starting_hashes.json"
final_hashes_json="/tmp/final_hashes.json"
impacted_targets_path="/tmp/impacted_targets.txt"
bazel_diff="/tmp/bazel_diff"

"$bazel_path" run :bazel-diff --script_path="$bazel_diff"

git -C "$workspace_path" checkout "$previous_revision" --quiet

$bazel_diff generate-hashes -w "$workspace_path" -b "$bazel_path" $starting_hashes_json

git -C "$workspace_path" checkout "$final_revision" --quiet

$bazel_diff generate-hashes -w "$workspace_path" -b "$bazel_path" $final_hashes_json

$bazel_diff get-impacted-targets -sh $starting_hashes_json -fh $final_hashes_json -o $impacted_targets_path

# First pretty print the targets for debugging

impacted_targets=()
IFS=$'\n' read -d '' -r -a impacted_targets < $impacted_targets_path || true
formatted_impacted_targets="$(IFS=$'\n'; echo "${impacted_targets[*]}")"

# Piping the output through to grep is flaky and will cause a broken pipe. Write the contents to a file
# and grep the file to avoid this.
echo "$formatted_impacted_targets" | tee /tmp/impacted_targets.txt

# Look for the patterns provided as arguments to this script. $formatted_impacted_targets contains
# a list of all the Bazel targets impacted by the changes between the two branches, so we just
# check to see if any of the provided patterns appear in the list of targets.

pattern_impacted() {
  grep -q "$1" /tmp/impacted_targets.txt
}

for pattern in "$@"
do
  if pattern_impacted "$pattern"; then
    echo "$pattern changed!"
    exit 0
  fi
done

# No relevant changes detected via Bazel.
echo "Nothing changed"
exit 1
