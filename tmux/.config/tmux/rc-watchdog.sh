#!/bin/bash
# Re-enable Claude Code Remote Control in tmux panes where it gave up.
#
# Claude Code stops retrying Remote Control after ~30 min of failures and prints
# "Remote Control disconnected — ... run /remote-control to reconnect". It
# exposes that state nowhere else (no hook, statusline field or transcript
# entry), so this reads it off the screen of every Claude pane.
#
# A pane needs a reconnect when its newest "Remote Control disconnected" line
# has no "/remote-control is active" line after it. /remote-control is typed
# only when the network is reachable, Claude is idle and the input is empty
# (dimmed ghost-text suggestions don't count). Failed attempts back off per
# pane: 1, 2, 5, then every 10 minutes, with no retry limit.
#
# Usage: rc-watchdog.sh [--dry-run] [--once]

INTERVAL=30
BACKOFF=(60 120 300 600)
PROBE_URL=https://api.anthropic.com/
STATE_DIR="${TMPDIR:-/tmp}/rc-watchdog"
LOG="$STATE_DIR/log"

DRY_RUN=0
ONCE=0
for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=1 ;;
    --once) ONCE=1 ;;
  esac
done

mkdir -p "$STATE_DIR"

log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$LOG"; }

# One instance per machine; the tmux.conf run-shell fires on every reload.
LOCK="$STATE_DIR/lock"
if [ "$DRY_RUN" = 0 ] && [ "$ONCE" = 0 ]; then
  if ! mkdir "$LOCK" 2>/dev/null; then
    if kill -0 "$(cat "$LOCK/pid" 2>/dev/null)" 2>/dev/null; then exit 0; fi
    rm -rf "$LOCK" && mkdir "$LOCK" || exit 0
  fi
  echo $$ > "$LOCK/pid"
  trap 'rm -rf "$LOCK"' EXIT
fi

network_up() {
  # Any HTTP response means the server is reachable; 000 means it isn't.
  local code
  code=$(curl -s -o /dev/null -m 10 -w '%{http_code}' "$PROBE_URL")
  [ "$code" != 000 ]
}

# Prints "needs" when the pane's latest Remote Control event is a disconnect.
rc_state() {
  tmux capture-pane -p -J -t "$1" -S -5000 2>/dev/null | awk '
    /^[[:space:]]*(⏺ )?Remote Control disconnected — /    { s = "needs" }
    /^[[:space:]]*(⎿ )?\/remote-control is active · / { s = "ok" }
    END { print s }'
}

# Idle = an input prompt is visible, its text is empty once dimmed ghost text
# is removed, and no "Thinking… (12s · …)" spinner line sits above it.
pane_idle() {
  local screen prompt
  screen=$(tmux capture-pane -p -e -t "$1" 2>/dev/null) || return 1
  prompt=$(printf '%s\n' "$screen" | grep '❯' | tail -1)
  [ -n "$prompt" ] || return 1
  prompt=$(printf '%s' "$prompt" \
    | sed -E $'s/\e\\[2m[^\e]*//g; s/\e\\[[0-9;]*m//g; s/^.*❯//; s/[[:space:]\xc2\xa0]//g')
  [ -z "$prompt" ] || return 1
  ! printf '%s\n' "$screen" | sed -E $'s/\e\\[[0-9;]*m//g' | tail -15 \
    | grep -qE '… \(([0-9]+[hms] ?)+'
}

check_pane() {
  local pane=$1 label=$2 key state attempts last now wait
  key="$STATE_DIR/${pane#%}"
  state=$(rc_state "$pane")
  if [ "$state" != needs ]; then
    [ -f "$key" ] && { log "$label: connected"; rm -f "$key"; }
    return
  fi

  attempts=0 last=0
  [ -f "$key" ] && read -r attempts last < "$key"
  now=$(date +%s)
  if [ "$attempts" -gt 0 ]; then
    i=$((attempts - 1)); [ $i -ge ${#BACKOFF[@]} ] && i=$((${#BACKOFF[@]} - 1))
    wait=${BACKOFF[$i]}
    [ $((now - last)) -ge "$wait" ] || return
  fi

  network_up || { log "$label: disconnected, network down, waiting"; return; }
  pane_idle "$pane" || { log "$label: disconnected, pane busy or has input, waiting"; return; }

  if [ "$DRY_RUN" = 1 ]; then
    echo "would reconnect $label"
    return
  fi
  log "$label: sending /remote-control (attempt $((attempts + 1)))"
  tmux send-keys -t "$pane" -l '/remote-control'
  sleep 0.5
  tmux send-keys -t "$pane" Enter
  echo "$((attempts + 1)) $now" > "$key"
}

while :; do
  # Claude Code runs as a binary named after its version, e.g. 2.1.294.
  tmux list-panes -a -F '#{pane_id} #{session_name}:#{window_index}.#{pane_index} #{pane_current_command}' 2>/dev/null \
    | while read -r pane label cmd; do
        case $cmd in
          claude | [0-9]*.[0-9]*.[0-9]*) ;;
          *) continue ;;
        esac
        [ "$DRY_RUN" = 1 ] && echo "$label ($pane): state=$(rc_state "$pane") idle=$(pane_idle "$pane" && echo yes || echo no)"
        check_pane "$pane" "$label"
      done
  [ "$ONCE" = 1 ] && break
  tmux list-sessions >/dev/null 2>&1 || exit 0
  sleep "$INTERVAL"
done
