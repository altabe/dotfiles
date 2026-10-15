#!/bin/bash
# Keep long-lived Claude Code sessions running in tmux, with Remote Control on.
#
# Run by launchd at login and every 10 minutes
# (~/Library/LaunchAgents/com.personal.claude-keepalive.plist). For each kept
# session it makes sure the tmux session and window exist and that Claude is
# running in it, resuming the conversation by ID if not. A pane whose Claude
# process has no Remote Control session gets /remote-control typed into it.
# Disconnects inside a running session are left to rc-watchdog.sh, which tmux
# starts from .tmux.conf.
#
# Kept sessions come from two places:
#   ~/.local/state/claude-keepalive/sessions  lines: <tmux-session> <window> <cwd> <session-uuid>
#   ~/personal/delegates.csv                  in-progress/blocked rows, kept in delegates:<name>
#
# Usage: claude-keepalive.sh [--dry-run]

MANIFEST="$HOME/.local/state/claude-keepalive/sessions"
DELEGATES="$HOME/personal/delegates.csv"
LOG="$HOME/Library/Logs/claude-keepalive.log"
SESSIONS_DIR="$HOME/.claude/sessions"

DRY_RUN=0
[ "$1" = --dry-run ] && DRY_RUN=1

mkdir -p "$(dirname "$LOG")"
log() {
  if [ "$DRY_RUN" = 1 ]; then echo "$*"; else printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$LOG"; fi
}
run() { [ "$DRY_RUN" = 1 ] || "$@"; }

# zsh -i loads .zshrc, so claude gets the usual PATH and alias (auto mode).
claude_cmd() { printf "zsh -ic 'claude --resume %s -n %s'" "$1" "$2"; }

targets() {
  [ -f "$MANIFEST" ] && grep -v '^\s*#' "$MANIFEST" | grep -v '^\s*$'
  [ -f "$DELEGATES" ] && python3 -I - "$DELEGATES" <<'EOF'
import csv, re, sys
for r in csv.DictReader(open(sys.argv[1], newline="")):
    if r["status"] in ("in-progress", "blocked") and re.fullmatch(r"[0-9a-f-]{36}", r["id"]):
        print("delegates", r["session"].replace(" ", "-"), "~/personal", r["id"])
EOF
}

is_claude() { case $1 in claude | [0-9]*.[0-9]*.[0-9]*) return 0 ;; esac; return 1; }

# The live Claude process for a session id records its Remote Control session
# as bridgeSessionId in ~/.claude/sessions/<pid>.json.
rc_bridge() {
  python3 -I - "$SESSIONS_DIR" "$1" <<'EOF'
import glob, json, os, sys
for f in glob.glob(os.path.join(sys.argv[1], "*.json")):
    try:
        d = json.load(open(f))
        os.kill(d["pid"], 0)
    except Exception:
        continue
    if d.get("sessionId") == sys.argv[2]:
        print(d.get("bridgeSessionId") or "none")
        break
EOF
}

# Same rule as rc-watchdog.sh: a prompt is visible, its input is empty once
# dimmed ghost text is removed, and no spinner line is running above it.
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

ensure() {
  local sess=$1 win=$2 cwd=${3/#\~/$HOME} id=$4 target="$1:$2" cmd bridge
  cmd=$(claude_cmd "$id" "$win")

  if ! tmux has-session -t "=$sess" 2>/dev/null; then
    log "$target: tmux session missing, creating it and resuming $id"
    run tmux new-session -d -s "$sess" -n "$win" -c "$cwd" "$cmd"
    return
  fi
  if ! tmux list-windows -t "=$sess" -F '#{window_name}' | grep -qxF "$win"; then
    log "$target: window missing, resuming $id"
    run tmux new-window -d -t "=$sess:" -n "$win" -c "$cwd" "$cmd"
    return
  fi

  # The window exists. If Claude exited back to a shell, start it again there.
  if ! is_claude "$(tmux display-message -p -t "=$sess:$win" '#{pane_current_command}')"; then
    log "$target: claude not running in pane, resuming $id"
    run tmux send-keys -t "=$sess:$win" -l "claude --resume $id -n $win"
    run tmux send-keys -t "=$sess:$win" Enter
    return
  fi

  bridge=$(rc_bridge "$id")
  if [ "$bridge" = none ]; then
    if pane_idle "=$sess:$win"; then
      log "$target: no Remote Control session, sending /remote-control"
      run tmux send-keys -t "=$sess:$win" -l '/remote-control'
      sleep 0.5
      run tmux send-keys -t "=$sess:$win" Enter
      # Close the status dialog it opens so the input box is usable again.
      sleep 5
      run tmux send-keys -t "=$sess:$win" Escape
    else
      log "$target: no Remote Control session, pane busy, retrying next run"
    fi
  elif [ -z "$bridge" ]; then
    log "$target: claude running but session $id not found in $SESSIONS_DIR"
  fi
}

targets | while read -r sess win cwd id; do
  [ -n "$id" ] && ensure "$sess" "$win" "$cwd" "$id"
done

# rc-watchdog.sh normally starts with the tmux server; start it if it's gone.
if tmux list-sessions >/dev/null 2>&1 && ! pgrep -f 'tmux/rc-watchdog.sh' >/dev/null; then
  log "rc-watchdog not running, starting it"
  run tmux run-shell -b "$HOME/.config/tmux/rc-watchdog.sh"
fi
