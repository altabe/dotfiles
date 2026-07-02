---
name: gas
description: Grep All Sessions — find an answer given once in some past Claude Code session. Give it a question that was previously answered; it greps relevant terms across all session logs to recover that answer. Optionally pass explicit terms you think will help locate it.
argument-hint: "<question that was answered before> [| explicit terms]"
allowed-tools: Bash, Read
---

# gas - Grep All Sessions

The user remembers that *something was figured out in a past chat* but not
where. Given a **question that was previously answered**, grep across every
Claude Code session log to recover the answer, then report it with the source
session so they can dig deeper if needed.

Sessions live at `~/.claude/projects/<encoded-cwd>/<uuid>.jsonl` (~hundreds of
files). Each line is a JSON object; `message.content` holds user text,
assistant text, `tool_use`, and `tool_result` blocks. `rg` searches the raw
JSONL fine — matches land on whichever line contains the term.

## Arguments

`$ARGUMENTS` is the **question** to find the answer to. Optionally the user
appends **explicit terms** they think will help (e.g. after a `|`, or phrased
as "grep for X and Y"). Explicit terms are hints — start with them, but don't
stop there if they come up empty.

## Execution

### Step 1 — Derive search terms

From the question, pull the distinctive, greppable tokens likely to appear in
the answer: identifiers, filenames, flags, error strings, command names, API
names, proper nouns. Prefer rare/specific tokens over common words. Generate a
few variants (synonyms, alternate casing, abbreviations) — the answer may
phrase things differently than the question. If the user gave explicit terms,
lead with those.

### Step 2 — Grep all sessions

Search every session log, case-insensitive, listing files with match counts so
you can rank where to look:

```bash
rg -il --glob '*.jsonl' 'TERM1|TERM2|TERM3' ~/.claude/projects | head -40
```

To see hits in context (the surrounding JSON line carries the message), run a
non-`-l` search on the top files, or add `-c` first to rank by match count:

```bash
rg -c --glob '*.jsonl' 'TERM' ~/.claude/projects | sort -t: -k2 -rn | head -20
```

Widen or narrow as needed: if nothing matches, broaden terms (drop to a single
distinctive token, try synonyms); if hundreds match, AND-combine terms
(`rg 'TERM1' file | rg 'TERM2'`) or add a more specific token.

### Step 3 — Read the answer out of the top matches

For the most promising files, pull the matching lines with a little context and
parse the relevant `message.content` (assistant text is usually where the
answer lives; `tool_result` blocks can hold command output that *is* the
answer). Pipe through `python3`/`jq` to extract readable text rather than
dumping raw JSON. Read enough around the match to capture the full answer, not
just the keyword.

Skip `thinking` blocks and `isMeta` lines. This is **read-only** — never write
to any `.jsonl`.

### Step 4 — Report

Give the user:
- **The answer** to their question, synthesized from what you found.
- **Where it came from**: session UUID prefix + project directory (+ rough
  time from the file's mtime) so they can resume it via `--resume` or the
  `import-session` skill if they want the full context.

If several sessions answered it differently (e.g. the approach evolved),
surface the most recent / most complete answer and note the others exist. If
nothing convincing turns up after broadening, say so plainly and show which
terms you tried — don't fabricate an answer.
