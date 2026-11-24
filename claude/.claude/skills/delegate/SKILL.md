---
name: delegate
description: Hand a complex task to its own long-lived Claude session, one the user will discuss and steer over several turns, in a tmux window grouped under the delegating session, logged in ~/personal/delegates.csv. Use only for such tasks or when the user explicitly asks for a delegate or a separate session. A self-contained task that just needs a separate context and finishes in one go goes to a subagent (Agent tool), not here. Also used to list, message, close, reopen or update delegates.
argument-hint: "<task> | new <task> | find <words> | list | tree | status <name> <status> [note] | close <name> [--park] | reopen <name> | send <name|--all> <msg>"
allowed-tools: Bash, Write
---

# delegate - hand a complex task to its own session

A delegate is a normal interactive Claude session for one task, in its own tmux
window, connected to Remote Control so the user can talk to it from the phone.
It is logged in `~/personal/delegates.csv` and kept alive until it's closed.

Helper: `python3 ~/.claude/skills/delegate/delegate.py` (below: `delegate.py`).

## Delegate or subagent?

Ask: **will the user need to talk to it more than once?**
- No (look something up, check a site, research a question, draft one thing):
  run a background subagent and report its result here. This is the usual case.
- Yes (a negotiation, a plan that needs his decisions, an ongoing assistant
  role like shopping lists): delegate.

`/delegate` typed by the user always delegates. A casual "delegate it" for a
clearly one-shot task runs as a subagent, with one line saying so: "Ran it as a
subagent; say /delegate if you want a session."

## Layout

Each delegate runs in tmux session `d-<parent>`, where `<parent>` is the name
of the session that delegated it (`d-pa:rent-contract`). A delegate can
delegate too, so its children go in `d-<its name>`: a tree. Empty `d-*`
sessions vanish when their last window exits. `delegate.py tree` shows it.

## Statuses

| status | meaning | kept alive |
|---|---|---|
| `in-progress` | working, or an active back-and-forth | yes |
| `waiting` | its turn ended on a question for the user (question in notes) | yes |
| `blocked` | waiting on someone else (reason in notes) | yes |
| `done` | finished; closed by the weekly sweep 48 h after the user's last message | no |
| `parked` | not finished, closed for now; reopen any time | no |

Delegates set their own status (see the prompt rules below). The delegator
also sets it when the user reports one.

`~/.config/tmux/claude-keepalive.sh` (launchd, every 10 min) resumes kept
delegates whose Claude process is gone, delivers queued messages, finishes
closes, and runs the weekly sweep. The sweep closes `done` delegates and never
closes unfinished ones; for those idle 30+ days it sends the delegating session
a `[delegate] Weekly delegate sweep` message. On receiving it, ask the user,
per delegate, whether to keep, park, or mark it done.

## Delegating a task

0. **Look for an existing delegate first.** Run `delegate.py find <key words>`
   with the task's main words (names, places, the thing itself). It ranks every
   delegate, closed ones too, and lists the other open delegates; judge those
   by meaning as well, since it only matches words. If one already covers the
   task, continue it instead of starting a new one:
   `delegate.py reopen <name> --message "<the request>"`. That hands a running
   delegate the request, or resumes a closed one first (`--fresh` too if its
   context is 150k+). Tell the user in one line ("Continued bike-fit instead
   of starting a new session"). If it's unclear which one fits, ask. `/delegate
   new` always starts a new one.

1. **Name it**: lowercase words joined by dashes, ideally 2 (`arnona-appeal`).
   `start` refuses a name an open delegate already has.

2. **Draft the prompt.**
   - Keep the user's intent; rephrase freely when terse or ambiguous, fix typos.
   - Keep the user's constraints exactly (location, scope, filters, order).
     Don't widen "in Tel Aviv" to "Tel Aviv or nearby"; ask first.
   - Write it for a fresh session with no memory of this chat: fill in names,
     dates, paths, URLs, decisions made and constraints set. Don't expand scope.
   - Include these rules, adapted to the task:
     - State lives in `~/personal/delegates/<name>/STATE.md` (create it), with
       sections: goal and scope, constraints and rules the user set, decisions
       made (with reason), current status, open questions, next steps. Other
       working data goes beside it, or in the task's natural home (a repo,
       `~/personal/shopping-lists/`), referenced from `STATE.md`.
     - Update `STATE.md` after every meaningful step, user decision or new
       fact, before replying. Write it for a reader with no memory of the
       conversation; rewrite stale parts instead of appending.
     - At the start and after any context reset, read `STATE.md` first.
     - Never store passwords, ID numbers or one-time codes in it.
     - Keep your status in the log current with
       `python3 ~/.claude/skills/delegate/delegate.py update --status <status> --notes "<short note>"`
       (no `--name` needed: it finds this session): `waiting` with the question
       when your reply ends on a question for Tomer; `in-progress` when he
       answers; `blocked` with the reason when waiting on someone else; `done`
       only when the whole task is finished. A request handled inside an
       ongoing role (shopping lists, coaching) isn't done: stay `in-progress`.
     - Messages starting with `[delegate]` are automated; follow them.
   - If the task may use Chrome: open your own tabs; record each in
     `STATE.md` (tab ID, URL, purpose) and note any the user asked to keep;
     leave them open while the task is in progress; close them when told
     you're being closed or once done, except the kept ones; never close tabs
     you didn't open.
   - End with a line containing exactly: `notify me when the task is done`

3. **Launch**: write the prompt to a scratchpad file, then
   `delegate.py start --name <name> --prompt-file <file> [--cwd <dir>]`.
   `--cwd` defaults to `~/personal`; use a repo when the task belongs to one.
   The directory must be one Claude already trusts, or the session sits on a
   trust dialog. The parent is this session, taken from the environment.

4. **Report** briefly: name, window, open command, and the prompt unless it's
   the user's wording unchanged. If `/pb` follows, copy the open command.

## Other commands

- `list [--all]`, `tree [--all]`: open delegates with status, idle time (since
  the user's last message), context size and notes. `--all` adds closed ones.
- `update --name <name> --status <status> [--notes ...]`: on the user's word,
  or when a delegate reports in.
- `open <name>`: prints the command that opens its window.
- `close <name> [--park] [--notes ...]`: asks the delegate to close its tabs
  and update `STATE.md`, then types `/exit` (on a later keepalive run if it's
  busy). Default status `done`; `--park` for unfinished. Only when the user
  asks, or for a delegate marked done. Never kill a window.
- `reopen <name> [--fresh] [--message ...]`: back to `in-progress` in its old
  window group, resuming the same session, then hands it the message if given
  (if it's running, it just gets the message). `--fresh` starts a new session
  from `STATE.md` instead; use it when the old context is large (150k+ tokens).
- `find <words>`: delegates of any status that mention these words.
- `send <name...> | --all | --children-of <name> --message "..."`: types a
  `[delegate]` message only into idle sessions with an empty input box and no
  open menu; others are queued and delivered later by keepalive. Use this for
  every message or broadcast to delegates; never `tmux send-keys` directly.
- **Handoff** to a fresh session for the same task: `start --name <new>
  --replaces <old>` with a prompt to read the old `STATE.md`. The new one takes
  the old one's place in the tree and the old one is closed as handed off.
- `doctor`: log vs reality (kept but not running, done but still running,
  renamed sessions, `d-*` windows with no row).
- `sweep --dry-run`: what the weekly sweep would do now.
