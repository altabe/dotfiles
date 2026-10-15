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
   - If the description is clear and self-contained, pass it **verbatim**.
   - If it depends on this conversation (for example "book that barber",
     "follow up on the arnona thing", or files and findings discussed earlier),
     rewrite it so a fresh session with no memory of this chat can act on it.
     Include the concrete facts it needs: names, dates, file paths, URLs,
     decisions already made, and constraints the user set. Don't add anything
     the user didn't ask for.
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
   command, and whether the prompt went verbatim or was adapted. If it was
   adapted, show the prompt.

The open command works both inside and outside tmux:
`tmux switch-client -t delegates:<name> 2>/dev/null || tmux attach -t delegates:<name>`.
If the user follows this skill with `/pb`, copy that command.

If a delegate's window is gone (the session exited or the machine rebooted),
reopen it in the same window with the logged UUID. An interactive `--resume`
keeps the session ID:
`tmux new-window -d -t delegates: -n <name> -c <cwd> "claude --resume <uuid> -n <name>"`.
Don't use `claude --bg`: background sessions are shut down after 8 hours idle,
and `--bg --resume` of a finished session created a copy with a new ID.

When a delegate is done and the user asks to close it, type `/exit` into its
window rather than killing the window (`tmux send-keys -t delegates:<name> -l /exit`, then Enter).

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
