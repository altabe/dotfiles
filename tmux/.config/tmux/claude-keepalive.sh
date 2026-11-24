#!/bin/bash
# Keep long-lived Claude Code sessions running in tmux, with Remote Control on.
#
# Run by launchd at login and every 10 minutes
# (~/Library/LaunchAgents/com.personal.claude-keepalive.plist). For each kept
# session it makes sure Claude is running, resuming the conversation by ID in
# its tmux session and window if not. A Claude process that has no Remote
# Control session gets /remote-control typed into it. Disconnects inside a
# running session are left to rc-watchdog.sh, which tmux starts from .tmux.conf.
#
# A session whose Claude process is alive counts as running wherever its window
# is, so windows can be moved between tmux sessions without being duplicated.
#
# Kept sessions come from two places:
#   ~/.local/state/claude-keepalive/sessions  lines: <tmux-session> <window> <cwd> <session-uuid>
#   ~/personal/delegates.csv                  in-progress/waiting/blocked delegates, kept in
#                                             d-<delegating session>:<name> (delegate.py keepalive-targets)
#
# Afterwards it runs `delegate.py tick`: queued messages to delegates, pending
# closes and the weekly sweep.
#
# Usage: claude-keepalive.sh [--dry-run]

MANIFEST="$HOME/.local/state/claude-keepalive/sessions"
DELEGATE_PY="$HOME/.claude/skills/delegate/delegate.py"
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
  [ -f "$DELEGATE_PY" ] && python3 -I "$DELEGATE_PY" keepalive-targets
}

is_claude() { case $1 in claude | [0-9]*.[0-9]*.[0-9]*) return 0 ;; esac; return 1; }

# For the live Claude process of a session id, prints "<bridge> <pane>":
# its Remote Control session (bridgeSessionId, or "none") and its tmux pane
# (%N, or "-"), from ~/.claude/sessions/<pid>.json. Prints nothing if no
# process is running that session.
live_info() {
  python3 -I - "$SESSIONS_DIR" "$1" <<'PY'
import glob, json, os, sys
for f in glob.glob(os.path.join(sys.argv[1], "*.json")):
    try:
        d = json.load(open(f))
        os.kill(d["pid"], 0)
    except Exception:
        continue
    if d.get("sessionId") == sys.argv[2]:
        t = d.get("tmux") or ""
        print(d.get("bridgeSessionId") or "none", t.rsplit(".", 1)[-1] if "%" in t else "-")
        break
PY
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

# Claude is running in <pane>; turn Remote Control on if it has none.
ensure_rc() {
  local target=$1 bridge=$2 pane=$3
  [ "$bridge" = none ] || return
  if pane_idle "$pane"; then
    log "$target: no Remote Control session, sending /remote-control"
    run tmux send-keys -t "$pane" -l '/remote-control'
    sleep 0.5
    run tmux send-keys -t "$pane" Enter
    # Close the status dialog it opens so the input box is usable again.
    sleep 5
    run tmux send-keys -t "$pane" Escape
  else
    log "$target: no Remote Control session, pane busy, retrying next run"
  fi
}

ensure() {
  local sess=$1 win=$2 cwd=${3/#\~/$HOME} id=$4 target="$1:$2" cmd info bridge pane
  cmd=$(claude_cmd "$id" "$win")

  info=$(live_info "$id")
  if [ -n "$info" ]; then
    read -r bridge pane <<< "$info"
    [ "$pane" = - ] && pane="=$sess:$win"
    ensure_rc "$target" "$bridge" "$pane"
    return
  fi

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
  log "$target: claude running in window but session $id not found in $SESSIONS_DIR"
}

targets | while read -r sess win cwd id; do
  [ -n "$id" ] && ensure "$sess" "$win" "$cwd" "$id"
done

# Queued messages to delegates, pending closes and the weekly sweep.
if [ -f "$DELEGATE_PY" ]; then
  if [ "$DRY_RUN" = 1 ]; then
    echo "would run: delegate.py tick"
  else
    python3 -I "$DELEGATE_PY" tick 2>&1 | while read -r line; do log "delegate: $line"; done
  fi
fi

# rc-watchdog.sh normally starts with the tmux server; start it if it's gone.
if tmux list-sessions >/dev/null 2>&1 && ! pgrep -f 'tmux/rc-watchdog.sh' >/dev/null; then
  log "rc-watchdog not running, starting it"
  run tmux run-shell -b "$HOME/.config/tmux/rc-watchdog.sh"
fi
