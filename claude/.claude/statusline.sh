#!/bin/bash
input=$(cat)
DIR=$(echo "$input" | jq -r '.workspace.current_dir // empty')
if [ -z "$DIR" ]; then
  DIR=$(pwd)
fi

MODEL=$(echo "$input" | jq -r '.model.display_name // .model.id // empty')
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')
SID=$(echo "$input" | jq -r '.session_id // empty' | cut -c1-8)

# Claude Code's own context readout only appears in the last 20k tokens of the
# window, so on a 1M-context model it is effectively never shown. Render it
# ourselves instead. used_percentage is null until the first API response.
CTX=$(echo "$input" | jq -r '
  def hum: if . >= 1000000 then (./1000000*10|round/10|tostring) + "M"
           elif . >= 1000 then (./1000|round|tostring) + "k"
           else tostring end;
  .context_window as $c
  | if ($c.used_percentage // null) == null then empty
    else "\($c.total_input_tokens|hum)/\($c.context_window_size|hum) (\($c.used_percentage|round)%)"
    end')

BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
if [ -n "$BRANCH" ]; then
  LOC=$(printf "%s (%s)" "$DIR" "$BRANCH")
else
  LOC="$DIR"
fi

TAG="$MODEL"
if [ -n "$EFFORT" ]; then
  if [ -n "$TAG" ]; then
    TAG="$TAG · $EFFORT"
  else
    TAG="$EFFORT"
  fi
fi

if [ -n "$SID" ]; then
  LOC="$LOC · $SID"
fi

if [ -n "$CTX" ]; then
  LOC="$LOC · $CTX"
fi

if [ -n "$TAG" ]; then
  printf "[%s] %s" "$TAG" "$LOC"
else
  printf "%s" "$LOC"
fi
