#!/usr/bin/env bash
# Poll a PR until a bot reacts to it, reviews it, or comments on it after SINCE.
# Usage: wait_for_review.sh <owner/repo> <number> <since: ISO-8601 UTC> [timeout-min]
# Prints one of: APPROVED | REVIEWED | COMMENTED | TIMEOUT
set -euo pipefail
repo=$1 num=$2 since=$3 timeout=${4:-20}

for ((i = 0; i < timeout * 2; i++)); do
  approved=$(gh api "repos/$repo/issues/$num/reactions" --paginate --jq \
    "[.[] | select((.user.login | test(\"codex\")) and .content == \"+1\" and .created_at > \"$since\")] | length")
  [[ $approved -gt 0 ]] && echo APPROVED && exit 0

  reviewed=$(gh api "repos/$repo/pulls/$num/reviews" --paginate --jq \
    "[.[] | select(.user.type == \"Bot\" and .submitted_at > \"$since\")] | length")
  [[ $reviewed -gt 0 ]] && echo REVIEWED && exit 0

  commented=$(gh api "repos/$repo/issues/$num/comments" --paginate --jq \
    "[.[] | select(.user.type == \"Bot\" and .created_at > \"$since\")] | length")
  [[ $commented -gt 0 ]] && echo COMMENTED && exit 0

  sleep 30
done
echo TIMEOUT
