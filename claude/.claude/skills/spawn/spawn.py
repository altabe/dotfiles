#!/usr/bin/env python3
"""Start an interactive Claude session in a window of the "spawn" tmux session.

  spawn.py --name NAME --prompt-file FILE [--cwd DIR]
"""
import argparse
import os
import shlex
import subprocess
import sys
import uuid

TMUX_SESSION = "spawn"


def tmux(*argv):
    return subprocess.run(["tmux", *argv], capture_output=True, text=True)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--name", required=True)
    p.add_argument("--prompt-file", required=True)
    p.add_argument("--cwd", default=os.getcwd())
    args = p.parse_args()

    with open(args.prompt_file) as f:
        prompt = f.read().strip()
    if args.name in tmux("list-windows", "-t", f"={TMUX_SESSION}", "-F", "#{window_name}").stdout.split():
        sys.exit(f"a window named {args.name!r} already exists in tmux session {TMUX_SESSION!r}")
    sid = str(uuid.uuid4())
    cmd = " ".join(shlex.quote(a) for a in ["claude", "-n", args.name, "--session-id", sid, prompt])
    # zsh -i loads .zshrc, so claude gets the usual PATH and alias.
    cmd = f"zsh -ic {shlex.quote(cmd)}"
    cwd = os.path.expanduser(args.cwd)
    if tmux("has-session", "-t", f"={TMUX_SESSION}").returncode == 0:
        out = tmux("new-window", "-d", "-t", f"={TMUX_SESSION}:", "-n", args.name, "-c", cwd, cmd)
    else:
        out = tmux("new-session", "-d", "-s", TMUX_SESSION, "-n", args.name, "-c", cwd, cmd)
    if out.returncode != 0:
        sys.exit(f"tmux failed: {out.stderr}")
    target = f"{TMUX_SESSION}:{args.name}"
    print(f"id: {sid}\nwindow: {target}\ncwd: {cwd}\n"
          f"open: tmux switch-client -t {target} 2>/dev/null || tmux attach -t {target}")


if __name__ == "__main__":
    main()
