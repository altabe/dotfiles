#!/usr/bin/env bash
# Joins lines that were soft-wrapped by tmux at the pane boundary,
# so copied text doesn't contain artificial newlines from narrow panes.
pw=$(tmux display-message -p '#{pane_width}')
awk -v pw="$pw" '
{
  if (NR > 1) {
    if (length(prev) >= pw)
      printf "%s", prev
    else
      printf "%s\n", prev
  }
  prev = $0
}
END {
  if (prev != "") printf "%s", prev
}'
