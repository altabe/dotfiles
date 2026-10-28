---
name: delegate
description: Hand a task off to a new Claude session in its own window of the "delegates" tmux session and log it in ~/personal/delegates.csv. Use when the user wants a task, usually a multi-step one, moved out of the current conversation. Also used to update or list delegated tasks.
argument-hint: "<task description> | status <name> <in-progress|blocked|done> [note] | list"
allowed-tools: Bash, Write
---

# delegate - hand a task to its own session

The user runs many unrelated tasks through one assistant session. This skill
moves a task into its own named Claude session, running in a window of the
dedicated `delegates` tmux session, and keeps a log of every delegated task.
These are normal interactive sessions, so they don't time out when idle.
They connect to remote control at startup, and the tmux watchdog
(`~/.config/tmux/rc-watchdog.sh`) reconnects them if it drops.

Helper script: `~/.claude/skills/delegate/delegate.py`
Log file: `~/personal/delegates.csv`, with columns
`datetime, session, id, status, prompt, notes`.

## Arguments

`$ARGUMENTS` is one of:
- **A task description**: delegate it (the default).
- **`status <name|id> <in-progress|blocked|done> [note]`**: update a logged task.
  For `blocked`, put the reason in the note.
- **`list`**: show the log.

## Delegating a task

1. **Name the session.** Use lowercase words joined by dashes, ideally at most
   2 words (`running-trainer`, `arnona-appeal`). Use 3 only when 2 would be
   ambiguous. The name is also the tmux window name. Check `delegate.py list`
   so it isn't already taken by an active delegate; the script refuses a name
   that already has a window.

2. **Draft the initial prompt.**
   - Start from the user's description and keep their intent. Keeping their
     exact wording is not a goal: rephrase freely when it's incomplete,
     ambiguous or terse, and fix typos.
   - Write it so a fresh session with no memory of this chat can act on it.
     When it depends on this conversation (for example "book that barber",
     "follow up on the arnona thing", or files and findings discussed earlier),
     fill in the concrete facts it needs: names, dates, file paths, URLs,
     decisions already made, and constraints the user set. Don't expand the
     scope beyond what the user asked for.
   - Tell the delegate to keep its state in local files, so a context reset
     (`/clear`, compaction) or a handoff to a fresh session is trivial. Include
     these instructions in the prompt, adapted to the task:
     - The state lives in `~/personal/delegates/<name>/` (create it). The
       entry point is `STATE.md`, with these sections: goal and scope,
       constraints and rules the user set, decisions made (with the reason),
       current status, open questions, and next steps. Put other working data
       (lists, drafts, findings, links, screenshots) in files beside it, and
       reference them from `STATE.md`.
       - If the task already has a natural home for its data (for example a
         repo, or a folder like `~/personal/shopping-lists/`), keep the data
         there and have `STATE.md` point to it.
     - Update `STATE.md` after every meaningful step, user decision or new
       fact, before replying. Don't leave it until the end. The files, not
       the conversation, are the source of truth.
     - Write it for a reader with no memory of the conversation. Keep it
       current: rewrite stale parts instead of appending a log.
     - At the start, and after any context reset, read `STATE.md` first and
       continue from it.
     - Never store passwords, ID numbers or one-time codes in it.
   - If the task may use Chrome, tell the delegate to:
     - Open its own tabs.
     - Record each tab it opens in `STATE.md` (tab ID, URL and purpose), and
       note there any tab the user asked to keep.
     - Leave its tabs open while the task is in progress, because the user may
       be looking at them.
     - Once the task is done (the user confirms, or it's marked `done`),
       close the tabs it opened, except the ones the user asked to keep. Then
       clear the list in `STATE.md`.
     - Never close tabs it didn't open.
   - Always end the prompt with a new line containing exactly:
     `notify me when the task is done`

3. **Launch and log.** Write the prompt to a file in the scratchpad, then run:

   ```
   python3 ~/.claude/skills/delegate/delegate.py start --name <name> --prompt-file <file> [--cwd <dir>]
   ```

   `--cwd` defaults to `~/personal`. Pass a more specific directory only when
   the task clearly belongs to one, for example a repo. The script generates a
   session UUID and runs `claude -n <name> --session-id <uuid> "<prompt>"` in a
   new window `delegates:<name>`, creating the `delegates` tmux session if it
   doesn't exist. It appends an `in-progress` row to the log and prints the
   UUID and the open command.

4. **Report** in a few lines: the session name, the tmux window, the open
   command, and the prompt as sent, unless it's the user's wording unchanged.

The open command works both inside and outside tmux:
`tmux switch-client -t delegates:<name> 2>/dev/null || tmux attach -t delegates:<name>`.
If the user follows this skill with `/pb`, copy that command.

To reset a delegate's context or hand its task to a new session, start the
new session with a prompt telling it to read
`~/personal/delegates/<name>/STATE.md` and continue from there.

If a delegate's window is gone (the session exited or the machine rebooted),
reopen it in the same window with the logged UUID. An interactive `--resume`
keeps the session ID:
`tmux new-window -d -t delegates: -n <name> -c <cwd> "claude --resume <uuid> -n <name>"`.
Don't use `claude --bg`: background sessions are shut down after 8 hours idle,
and `--bg --resume` of a finished session created a copy with a new ID.

In-progress and blocked delegates are kept alive by
`~/.config/tmux/claude-keepalive.sh` (launchd, every 10 minutes), which
resumes any whose window or Claude process is gone. So mark a delegate `done`
*before* closing it, or it will be reopened.

When a delegate is done and the user asks to close it, type `/exit` into its
window rather than killing the window (`tmux send-keys -t delegates:<name> -l /exit`, then Enter).

Clean up its Chrome tabs when a delegate is marked `done`:
1. If its session is still running, ask it to close its tabs first.
2. Otherwise, or if any are left, the delegator closes them. Use the tabs
   listed in its `~/personal/delegates/<name>/STATE.md`, and keep any the
   user asked to keep.
3. Only close tabs that are listed there, or that are clearly that delegate's
   (in the shared tab group, with a URL tied to its task). If unsure, list
   them for the user instead of closing them.

## Updating status

When the user reports a delegate's status, or a delegated session reports
back that it's done or blocked, run:

```
python3 ~/.claude/skills/delegate/delegate.py update --name <name|id> --status <status> [--notes "<reason>"]
```

Statuses are `in-progress`, `blocked` and `done`. Don't change the status
without that signal.

## Listing

`python3 ~/.claude/skills/delegate/delegate.py list` prints one line per delegate.
