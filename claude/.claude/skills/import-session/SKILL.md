---
name: import-session
description: Load context from another Claude Code session (by id, prefix, or name) so you can answer the user's questions about whatever is being discussed there. Use when the user wants to talk about another chat without opening it.
argument-hint: <session-id-or-name>
allowed-tools: Bash, Read, AskUserQuestion
---

# import-session

Read the tail of another Claude Code session and figure out what it's about, then summarize it so the user can ask you questions about it. The user stays in *this* chat — you pull the other session's context in here.

## Arguments

`$ARGUMENTS` identifies the other session. Resolve it in this order:

1. **Full UUID** (`01f6d335-98dc-41bf-823b-6b03e5ae59a8`) → match a `<uuid>.jsonl` file directly.
2. **UUID prefix or 8-char short** (`01f6d335` or even `01f`) → match any `<uuid>.jsonl` whose filename starts with that string. Also matches the daemon `short` id used in `~/.claude/jobs/<short>/`.
3. **Session name — full or partial** (`refactor-bedrock-agentic-loop`, `slime-debug`, `na-sft`, or just a distinctive word like `triage` — names set via the `rename` skill or auto-derived) → look up in **`~/.claude/sessions/*.json` first**. This is the same name→session index that `claude --resume <name>` consults, so if `--resume <name>` works instantly, the name is here. Each file is keyed by PID and has a `name` field plus a `sessionId` (UUID) and `cwd`; resolve the `.jsonl` at `~/.claude/projects/<encoded-cwd>/<sessionId>.jsonl` (encoded-cwd = the cwd with every `/` replaced by `-`).

   The fastest lookup — including for a **partial/substring** name — is to grep the index directly (each file is one JSON line, so the whole record comes back):

   ```bash
   rg -il '<fragment>' ~/.claude/sessions/*.json   # case-insensitive; e.g. rg -il triage
   ```

   Matching order: exact `name` → case-insensitive substring. If the fragment is unique (one file matches), pull its `sessionId` + `cwd` and go straight to the `.jsonl` — no content grepping needed. If several match, list them and disambiguate per the rule below.

   **Only if nothing matches there**, fall back to `~/.claude/jobs/*/state.json` (daemon/background sessions only — interactive renamed sessions are *not* here). Each `state.json` has a `name` and either a `linkScanPath` (direct `.jsonl` path) or a `sessionId`.
4. **`latest` / `recent` / `last`** → the most recently modified `.jsonl` under `~/.claude/projects/`.

If nothing matches, tell the user and stop — do **not** silently fall back to a project-directory substring match; "name" here means a real session name, not a path component. If multiple sessions match (common for UUID prefix or substring name match), list the top 5 most-recent matches with their name + UUID prefix + cwd + last-modified time, and ask the user which one via `AskUserQuestion`.

### Tips for the name lookup

```bash
# Primary index — same one `claude --resume <name>` uses (interactive + renamed sessions)
for f in ~/.claude/sessions/*.json; do
  python3 -c "import json; d=json.load(open('$f')); print(repr(d.get('name')), d.get('sessionId'), d.get('cwd'))"
done

# Fallback — daemon/background jobs only
for f in ~/.claude/jobs/*/state.json; do
  python3 -c "import json; d=json.load(open('$f')); print(repr(d.get('name')), d.get('sessionId'), d.get('linkScanPath',''))"
done
```

Given a hit, build the `.jsonl` path from `sessionId` + `cwd`: `~/.claude/projects/$(echo <cwd> | sed 's#/#-#g')/<sessionId>.jsonl`.

`nameSource` distinguishes user-set renames (field absent/`null`) from auto-`derived` names — both are valid lookup keys, but if a user-set name and a derived name collide on a substring search, prefer the user-set one.

## Execution

### Step 1 — Locate the session file

Sessions live at `~/.claude/projects/<encoded-cwd>/<uuid>.jsonl`. Run something like:

```bash
find ~/.claude/projects -name "*.jsonl" -type f -printf "%T@ %p\n" | sort -rn
```

…and filter the results in-shell to apply the matching rules above. Do not invent a path — verify the file exists with `ls` before reading.

### Step 2 — Read the tail

Use `tail` on the resolved `.jsonl` to get the last chunk of lines (default: `tail -n 80`). Each line is a JSON object — parse only the meaningful ones:

- `type == "user"` with a string or list-of-blocks `message.content` → user text (skip `<local-command-*>` caveats and tool results, but **keep** real user messages).
- `type == "assistant"` with `message.content` → assistant turns. Extract `text` blocks; for `tool_use` blocks just note the tool name; for `thinking` blocks, ignore the body.
- Skip `file-history-snapshot`, `system`, and anything `isMeta: true`.

Pipe the tail through `python3` to do the JSON parsing — `jq` works too but Python is more forgiving with the varied schemas. Trim each extracted text to a few hundred chars per block so the context stays focused. If the tail doesn't contain any real user/assistant text (e.g., it was all tool I/O), widen the window (`tail -n 300`) and try again.

### Step 3 — Summarize what's going on

In 2–4 short bullets, tell the user:
- Which session you loaded (UUID prefix + project directory + last-modified time)
- What the other chat is about (topic, current question, blocker)
- Where it appears to have left off

Keep this tight. The user can already see the timestamp; they want the *topic*.

After the summary, the user will ask their own questions about the other session — they already know what they want to discuss. Answer them using the context you loaded, referring back to what you read so the user doesn't have to re-explain.

## Rules

- **Read-only.** Never write to the other session's `.jsonl` file. Never invoke any tool that could modify it.
- Do not dump the raw tail output to the user — they don't want a JSON wall. Synthesize.
- Do not include the `thinking` block contents in your summary even if you parsed them out — they're internal.
- If the other session is in a different project directory, *do not* `cd` into it or run commands there. You're just reading its log from this cwd.
- If `$ARGUMENTS` is empty, ask the user which session they want (offer "latest" as the default option).
