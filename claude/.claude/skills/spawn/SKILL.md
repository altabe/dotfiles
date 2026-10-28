---
name: spawn
description: Run a subtask in a separate, interactive Claude session in its own tmux window, outside the current context, where the user can watch it and talk to it directly. Use when the user wants a side task done without filling this conversation, but still wants to follow or steer it (which a subagent doesn't allow). The spawned session isn't tracked and doesn't report back.
argument-hint: "<task description>"
allowed-tools: Bash, Write
---

# spawn - run a subtask in its own interactive session

This starts a new, ordinary interactive Claude session for a subtask, in a
window of the `spawn` tmux session. The user can open that window or the
session's Remote Control link to watch it and talk to it. Unlike a subagent,
it doesn't run inside this conversation, so its work doesn't fill this
context.

The spawned session is on its own after it starts:
- Nothing records it except the window, and this session's report of its ID.
- It doesn't report back to this session. The user follows it directly.
- Nothing restarts it if its window closes or the machine reboots.

Helper script: `~/.claude/skills/spawn/spawn.py`

`$ARGUMENTS` is the task description.

## Steps

1. **Name the session.** Use lowercase words joined by dashes, ideally at most
   2 words (`fix-ci`, `tax-forms`). The name is also the tmux window name, and
   the script refuses a name that already has a window in `spawn`.

2. **Draft the initial prompt.**
   - Start from the user's description and keep their intent. Rephrase freely
     when it's incomplete, ambiguous or terse, and fix typos.
   - Write it for a fresh session with no memory of this chat. Fill in the
     concrete facts it needs from this conversation: names, dates, file paths,
     URLs, decisions already made, and constraints and rules the user set.
     Don't expand the scope beyond what the user asked for.
   - Tell it to keep its state in a file, so a context reset or a handoff to
     another session is trivial:
     - The state lives in `~/.local/state/spawn/<name>/STATE.md` (create it),
       with sections: goal and scope, constraints and rules, decisions made
       (with the reason), current status, open questions, next steps. Other
       working data goes beside it, or in the task's natural home (for
       example the repo it works in), referenced from `STATE.md`.
     - Update `STATE.md` after every meaningful step, user decision or new
       fact, before replying. Write it for a reader with no memory of the
       conversation, and rewrite stale parts instead of appending a log.
     - At the start, and after any context reset, read `STATE.md` first.
     - Never store passwords, ID numbers or one-time codes in it.
   - If the task may use Chrome, tell it to open its own tabs, record each
     one in `STATE.md` (tab ID, URL, purpose), leave them open while the task
     is in progress, close them once the user confirms it's done (except any
     the user asked to keep), and never close tabs it didn't open.
   - Don't tell it to report back to this session.

3. **Launch.** Write the prompt to a file in the scratchpad, then run:

   ```
   python3 ~/.claude/skills/spawn/spawn.py --name <name> --prompt-file <file> [--cwd <dir>]
   ```

   `--cwd` defaults to this session's working directory. Pass another one
   when the subtask clearly belongs elsewhere, for example a different repo.

4. **Report** in a few lines: the session name, the tmux window, the open
   command, the session ID (nothing else records it), and the prompt as sent,
   unless it's the user's wording unchanged.

## Later

- **Reopen** a closed window with its ID:
  `tmux new-window -d -t spawn: -n <name> -c <cwd> "zsh -ic 'claude --resume <uuid> -n <name>'"`.
- **Hand off** to a fresh session: start one with a prompt to read
  `~/.local/state/spawn/<name>/STATE.md` and continue.
- **Close** it by typing `/exit` into its window
  (`tmux send-keys -t spawn:<name> -l /exit`, then Enter), not by killing the
  window, and only when the user asks.
