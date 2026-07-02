---
name: pbn
description: Copy multiple items to the clipboard joined by a separator (newline by default) using pbcopy. Use when the user wants several values/lines combined into one clipboard payload.
argument-hint: "[items to copy] [separator]"
allowed-tools: Bash
---

# pbn - Copy Multiple Items to Clipboard

Copy several items to the clipboard via `pbcopy`, joined by a separator. Same
idea as the `pb` skill, but for a *list* of items combined into one payload.

## Arguments

`$ARGUMENTS` describes the items to copy and, optionally, the separator.

- **Items**: the list of things to join and copy (values, paths, lines,
  results, etc.). Infer them from the request or from prior context the same
  way `pb` does when arguments are omitted.
- **Separator**: a **newline (`\n`) by default**. Only use a different
  separator when the user explicitly states one (e.g. "comma-separated",
  "join with `, `", "space between them").

## Execution

1. Determine the exact ordered list of items and the separator.
2. Join the items with the separator and pipe the result into `pbcopy`. **Do
   not append a trailing separator or an extra trailing newline** beyond what
   the joined content itself contains — the user pastes this where a stray
   `\n` or dangling delimiter breaks things.

   - **Newline-separated** (the default): `printf '%s\n'` per item drops a
     final newline, so strip it. Simplest reliable form — pass items to
     `printf` and trim the last byte:

     ```
     printf '%s\n%s\n%s' 'item1' 'item2' 'item3' | pbcopy
     ```

     (interleave the literal `\n` yourself so no trailing newline is added), or
     build the joined string and use `printf '%s'`:

     ```
     printf '%s' "$(printf '%s\n' item1 item2 item3 | head -c -1)" | pbcopy
     ```

   - **Custom separator** (e.g. `, `): join with that exact separator and copy
     via `printf '%s'` so nothing extra is appended:

     ```
     printf '%s' 'item1, item2, item3' | pbcopy
     ```

   If in doubt, verify with `pbpaste | xxd | tail -1` — the last byte must not
   be `0a` (or a stray separator) unless the content genuinely ends that way.

3. Confirm what was copied in one short line — mention the item count and the
   separator used (e.g. "Copied 3 items, newline-separated").
