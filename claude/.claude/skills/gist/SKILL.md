---
name: gist
description: Summarize the previous (too-long) message into a short numbered list. Use when the last response was too long and the user wants the gist without reading it.
argument-hint: "[optional focus, e.g. 'just the decisions']"
allowed-tools:
---

# gist - Give Me the Gist

The previous message was too long. Boil it down to the essentials, written as
if the user **never read a word of it** — no "as I mentioned above", no
back-references, no assuming they saw any part of it.

## What to summarize

The **immediately preceding message** (the last substantial thing you sent). If
`$ARGUMENTS` names a focus (e.g. "just the decisions", "only the commands"),
narrow the gist to that; otherwise cover the whole message's key points.

## Execution

1. Extract the core points — the conclusions, decisions, answers, and any
   action items or commands. Drop preamble, caveats, restated context, and
   elaboration.
2. Output a **numbered list**. Group items by related topic so points about the
   same thing sit together, and — where it doesn't hurt the flow — put action
   items toward the end. Each item is one tight, self-contained line that
   stands on its own without the original text.
3. Be as short as the content allows without dropping anything that matters —
   merge related points and don't pad, but don't force brevity: if the original
   is genuinely dense, a longer list is fine. Length should track the content,
   not a fixed cap.
4. Preserve exact, must-be-precise details verbatim inside the relevant item
   (commands, filenames, flags, numbers) — summarize the prose around them, not
   these.
5. No intro or outro sentence — just the list. If a single sentence genuinely
   captures it, one line is fine.
