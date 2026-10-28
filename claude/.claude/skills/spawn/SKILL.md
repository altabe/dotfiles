---
name: spawn
description: Hand a task off to a new Claude session in its own window of the "delegates" tmux session, like /delegate, but without logging it in ~/personal/delegates.csv and without the session reporting back. Use when the user wants a task moved out of the current conversation and won't need it tracked.
argument-hint: "<task description>"
allowed-tools: Bash, Write
---

# spawn - hand off a task without tracking it

Like the `delegate` skill (`~/.claude/skills/delegate/SKILL.md`), this moves a
task into its own named Claude session in a window of the `delegates` tmux
session. Two things differ:

- **No log.** The task isn't added to `~/personal/delegates.csv`.
- **No report back.** The new session doesn't notify this one when it's done.
  The user follows it directly.

Because it isn't logged, `~/.config/tmux/claude-keepalive.sh` doesn't keep it
alive. If its window closes or the Mac reboots, it stays closed until someone
resumes it with its UUID. If the user wants it kept alive or tracked, use
`/delegate` instead.

`$ARGUMENTS` is the task description.

## Steps

1. **Name the session** by the delegate skill's rules: lowercase words joined
   by dashes, ideally at most 2. Make sure no window in the `delegates` tmux
   session already has that name (`tmux list-windows -t delegates -F '#{window_name}'`).

2. **Draft the initial prompt** exactly as in the delegate skill's step 2.
   That covers rephrasing, filling in context from this conversation, keeping
   state in `~/personal/delegates/<name>/STATE.md`, and the Chrome tab rules.
   The one difference: **don't** end it with `notify me when the task is done`,
   and don't tell it to message this session.

3. **Launch** without logging. Write the prompt to a file in the scratchpad,
   then run:

   ```
   python3 ~/.claude/skills/delegate/delegate.py start --no-log --name <name> --prompt-file <file> [--cwd <dir>]
   ```

   It prints the session UUID and the open command.

4. **Report** in a few lines: the session name, the tmux window, the open
   command, the UUID (it's recorded nowhere else), and the prompt as sent,
   unless it's the user's wording unchanged.

To reopen a closed window, use the UUID:
`tmux new-window -d -t delegates: -n <name> -c <cwd> "claude --resume <uuid> -n <name>"`.
To close it, type `/exit` into its window (`tmux send-keys -t delegates:<name> -l /exit`,
then Enter). Don't kill the window.
