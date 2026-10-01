---
name: pb
description: Copy text to the clipboard using pbcopy. Use with a description of what to copy, or without arguments when it's obvious from context or to repeat a previous copy.
argument-hint: "[what to copy]"
allowed-tools: Bash
---

# pb - Copy to Clipboard

Copy text to the clipboard via `pbcopy`.

## Arguments

`$ARGUMENTS` is an optional description of what to copy.

- **With arguments**: the description tells you what content to put in the clipboard.
- **Without arguments**: infer what to copy from one of these cases:
  1. It is obvious from the prior message what should be copied (e.g. the user just asked you to generate a command, snippet, or value).
  2. You already copied something to the clipboard earlier in the conversation and the user wants it again (it was likely overwritten since).

## Execution

1. Determine the exact text to copy.
2. Pipe it into `pbcopy` using the Bash tool. **Do not introduce a trailing
   newline** beyond what the content itself contains — the user pastes
   copied strings into shells, URL bars, and form fields where a stray
   `\n` triggers premature submission or breaks the paste.

   - **Single-line content** (paths, SHAs, IDs, one-liners): use `printf` so
     no newline is appended.

     ```
     printf '%s' '<content>' | pbcopy
     ```

   - **Multi-line content** where the body has its own line breaks: a
     heredoc is OK *only* if you strip the trailing newline heredocs
     append. `printf '%s'` from a variable or piping through `head -c -1`
     are both fine; otherwise prefer the printf form.

   If in doubt, verify with `pbpaste | xxd | tail -1` — the last byte
   must not be `0a` unless the original content ended with a newline.

3. Confirm what was copied in one short line.
