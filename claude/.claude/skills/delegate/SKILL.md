---
name: delegate
description: Hand a task off to a new background Claude session (claude --bg -n <name>) and log it in ~/personal/delegates.csv. Use when the user wants a task, usually a multi-step one, moved out of the current conversation. Also used to update or list delegated tasks.
argument-hint: "<task description> | status <name> <in-progress|blocked|done> [note] | list"
allowed-tools: Bash, Write
---

# delegate - hand a task to a background session

The user runs many unrelated tasks through one assistant session. This skill
moves a task into its own named background session so it can be worked on
separately, and keeps a log of every delegated task.

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
   ambiguous. Check `delegate.py list` so the name isn't already taken by an
   active delegate.

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
   the task clearly belongs to one, for example a repo. The script runs
   `claude --bg -n <name> "<prompt>"`, appends an `in-progress` row to the log,
   and prints the session id and the attach command.

4. **Report** in a few lines: the session name, the id, the attach command
   (`claude attach <id>`), and whether the prompt went verbatim or was
   adapted. If it was adapted, show the prompt.

If the user follows this with `/pb`, they want the attach command
(`claude attach <id>`) in the clipboard so they can open the new session.

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
