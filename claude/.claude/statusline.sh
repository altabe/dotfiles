#!/bin/bash
input=$(cat)
DIR=$(echo "$input" | jq -r '.workspace.current_dir // empty')
if [ -z "$DIR" ]; then
  DIR=$(pwd)
fi

MODEL=$(echo "$input" | jq -r '.model.display_name // .model.id // empty')
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')
SID=$(echo "$input" | jq -r '.session_id // empty' | cut -c1-8)

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

if [ -n "$TAG" ]; then
  printf "[%s] %s" "$TAG" "$LOC"
else
  printf "%s" "$LOC"
fi
