#!/usr/bin/env bash
# Fuzzy-search the content of every pane in every session, then jump to the hit.
# The built-in find-window (prefix f) can't do this: it glob-matches only the
# *visible* screen, and it lands on a window rather than the pane inside it.
# Here every pane's scrollback is flattened into an fzf index, so fzf scores and
# ranks matches -- "open stacked pr" finds "open a stacked PR for this".
# Capture uses -J, so a soft-wrapped prompt stays one searchable record.
#
# Runs inside display-popup, which -- unlike run-shell -- does NOT expand #{...}
# formats in its command, so there is no client name to pass in. The tmux calls
# below take no -c and resolve the client from the $TMUX the popup inherits.
set -eo pipefail

back=${TMUX_PANE_SEARCH_LINES:-3000}   # scrollback lines per pane to index

# Re-entrant preview: shows the matched line in context within its own pane.
if [[ ${1:-} == --preview ]]; then
  tmux capture-pane -p -J -S "-$back" -t "$2" 2>/dev/null |
    awk -v ln="$3" 'NR >= ln - 12 && NR <= ln + 12 {
      printf "%s%s\033[0m\n", (NR == ln ? "\033[1;33m> " : "  "), $0
    }'
  exit 0
fi

# index fields: pane_id \t line number \t session:window.pane \t text
# The line number is the position in this same capture so the preview can
# reproduce it; blank lines are dropped but still counted.
index() {
  tmux list-panes -a -F '#{pane_id} #{session_name}:#{window_index}.#{pane_index}' |
    while read -r pid label; do
      tmux capture-pane -p -J -S "-$back" -t "$pid" 2>/dev/null |
        awk -v pid="$pid" -v label="$label" '
          { sub(/[ \t]+$/, "") }
          length { printf "%s\t%d\t%s\t%s\n", pid, NR, label, $0 }
        '
    done
}

sel=$(index | fzf \
  --delimiter=$'\t' --with-nth=3,4 --ansi \
  --prompt='pane content> ' --info=inline --tiebreak=begin,length \
  --preview="$0 --preview {1} {2}" --preview-window='down,60%,wrap' \
  --header='fuzzy match across every pane in every session - Enter jumps to it') || exit 0

pid=${sel%%$'\t'*}
tmux switch-client -t "$(tmux display-message -p -t "$pid" '#{session_id}')"
tmux select-window -t "$pid"
tmux select-pane -t "$pid"
