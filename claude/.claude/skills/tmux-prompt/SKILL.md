---
name: tmux-prompt
description: Run a command that waits for typed input (a login asking for a verification code, a password or passphrase prompt, a y/n confirmation, an interactive installer) inside a detached tmux session, give the user what they need, and type their answer into it. Use when a command needs interactive input, especially after it crashed with EOFError or "EOF when reading a line" under the `!` prefix or the Bash tool, which cannot take typed input. Not for full-screen TUIs; use the spawn skill for those.
argument-hint: "[the interactive command]"
allowed-tools: Bash
---

# tmux-prompt: answer an interactive prompt for the user

Neither the Bash tool nor the user's `! command` prefix can answer a prompt: stdin is closed, so
`input()` and `read` hit end-of-file. Examples are `gcloud auth login --no-launch-browser`,
`az login --use-device-code` and `aws sso login --no-browser`. Instead, run the command in a
detached tmux session, read its prompt from the pane, and send the user's answer with
`tmux send-keys`.

## Steps

1. **Start it detached, wide, and kept alive.** A wide pane keeps long URLs on one line. The
   trailing `sleep` keeps the pane open after the command exits, so you can still read its
   result.

   ```bash
   tmux kill-session -t prompt 2>/dev/null
   tmux new-session -d -s prompt -x 400 -y 50 '<command>; sleep 600'
   sleep 4
   tmux capture-pane -p -t prompt -J | tail -20
   ```

   `-J` joins wrapped lines, so a URL comes out whole.

2. **Give the user what the prompt needs.** Pull out the URL or device code with
   `grep -o 'https://[^ ]*'`. Copy it to the user's clipboard when the pb skill or `pbcopy` is
   available, without a trailing newline: `... | tr -d '\n' | pbcopy`. Then say exactly what to
   do: "open the link, sign in, paste the code here".

3. **Type the answer when the user sends it.**

   ```bash
   tmux send-keys -t prompt '<answer>' Enter
   sleep 5
   tmux capture-pane -p -t prompt -J | tail -10
   ```

   Then check the result with a separate command, for example `gcloud auth list`. Don't rely
   only on what the pane shows.

4. **Clean up:** `tmux kill-session -t prompt`.

## Rules

- **Secrets.** Never put a password or passphrase into a command line or a file. Ask the user to
  type it into the pane themselves (`tmux attach -t prompt`, then detach with `Ctrl-b d`).
  One-time verification codes and device codes are fine to type for them. They expire and are
  useless once used.
- **Retries.** A login URL is tied to the process that printed it. If the command died, start a
  new session and give the user the new URL, not the old one.
- **Long-running sessions.** A session that has to stay up, such as a tunnel
  (`gcloud compute start-iap-tunnel`, `kubectl port-forward`), can use the same pattern: a named
  session, its output teed to a log file in the scratchpad, and that log checked before relying
  on it. Tunnels drop, so check the log again when a query fails.
- **Waiting.** Don't poll in a tight loop for the user. Ask, end your turn, and type the answer
  when it arrives.
