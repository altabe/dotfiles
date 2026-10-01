---
name: gist
description: Summarize everything the assistant sent since the user's last message into a short numbered list. Use when the response was too long and the user wants the gist without reading it.
argument-hint: "[optional focus, e.g. 'just the decisions']"
allowed-tools:
---

# gist - Give Me the Gist

The response was too long. Boil it down to the essentials, written as
if the user **never read a word of it** — no "as I mentioned above", no
back-references, no assuming they saw any part of it.

## What to summarize

**Everything the assistant sent since the user's previous message** — treat that
whole span as one answer and summarize all of it. The "response" the user wants
gisted is almost never a single message: between their last message and this
`/gist` you likely sent several messages across multiple tool-use turns
(progress notes, findings, results that arrived later, the final answer). The
user may not have read any of them. Gather the key content from **all** of those
messages, not just the last one — the most important point (a result, a number,
an answer to their question) frequently landed in an earlier message of the
span, not the final one.

Scope boundary: start at the user's most recent message and include every
assistant message after it, up to now. Do not reach back before that message. If
`$ARGUMENTS` names a focus (e.g. "just the decisions", "only the commands"),
narrow the gist to that; otherwise cover the whole span's key points.

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
6. Before finalizing, re-scan every assistant message since the user's last
   message and confirm each one's key content is represented. If a result or
   answer arrived in an earlier message of the span and isn't in the gist, add
   it. This check is mandatory — summarizing only the final message and dropping
   what earlier messages in the span delivered is the most common way this
   skill fails.
