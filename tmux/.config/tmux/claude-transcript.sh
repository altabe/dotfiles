#!/usr/bin/env bash
# Open the full conversation of the Claude Code session in a tmux pane in nvim.
# tmux scrollback of a Claude pane is unreliable -- a resize makes Claude redraw
# into history, leaving duplicated/missing lines -- and /resume only repaints the
# tail. The session's .jsonl under ~/.claude/projects is the complete record, so
# render that instead.
#
# Claude writes ~/.claude/sessions/<pid>.json with "tmux":"<session>:@<win>.%<pane>",
# which maps a tmux pane id to its live sessionId.
#
# Usage: claude-transcript.sh [pane_id]   (bound to M-v in .tmux.conf)
# display-popup doesn't expand #{...} in its command (see pane-search.sh), so with
# no argument ask tmux for the active pane of the client the popup is drawn over.
set -eo pipefail

pane=${1:-$(tmux display-message -p '#{pane_id}')}

sid=$(jq -r --arg p "$pane" 'select(.tmux // "" | endswith("." + $p)) | .sessionId' \
  ~/.claude/sessions/*.json 2>/dev/null | head -1)
if [[ -z $sid ]]; then
  echo "No running Claude Code session in pane $pane." >&2
  read -rsn1 -p "Press any key to close."
  exit 1
fi

log=$(find ~/.claude/projects -maxdepth 2 -name "$sid.jsonl" | head -1)
out=${TMPDIR:-/tmp}/claude-transcript-$sid.md

jq -r '
  select(.isSidechain != true and .isMeta != true) |
  if .type == "user" then
    (.message.content | if type == "string" then . else (map(select(.type == "text") | .text) | join("\n")) end) as $t |
    if $t == "" or ($t | startswith("<local-command-caveat")) then empty
    else "\n## ❯ \(.timestamp[0:19] | sub("T"; " "))\n\n\($t)" end
  elif .type == "assistant" then
    .message.content[]? |
    if .type == "text" then "\n\(.text)"
    elif .type == "tool_use" then
      "  ⏺ \(.name)(\((.input.command // .input.file_path // .input.pattern // .input.description // "") | tostring | gsub("\n"; " ") | .[0:160]))"
    else empty end
  else empty end' "$log" > "$out"

# Start at the bottom (latest message); search ❯ to step between prompts.
exec nvim -R -c 'set ft=markdown' -c 'normal! G' "$out"
