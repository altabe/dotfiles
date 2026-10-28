#!/usr/bin/env python3
"""Launch a Claude session in a tmux window and keep a CSV log of delegated tasks.

  delegate.py start --name NAME --prompt-file FILE [--cwd DIR]
  delegate.py update --name NAME --status STATUS [--notes TEXT]
  delegate.py list
"""
import argparse
import csv
import datetime
import os
import shlex
import subprocess
import sys
import uuid

LOG = os.path.expanduser("~/personal/delegates.csv")
TMUX_SESSION = "delegates"
FIELDS = ["datetime", "session", "id", "status", "prompt", "notes"]
STATUSES = ("in-progress", "blocked", "done")


def read_rows():
    if not os.path.exists(LOG):
        return []
    with open(LOG, newline="") as f:
        return list(csv.DictReader(f))


def write_rows(rows):
    with open(LOG, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS)
        w.writeheader()
        w.writerows(rows)


def tmux(*argv):
    return subprocess.run(["tmux", *argv], capture_output=True, text=True)


def open_command(name):
    target = f"{TMUX_SESSION}:{name}"
    return f"tmux switch-client -t {target} 2>/dev/null || tmux attach -t {target}"


def start(args):
    with open(args.prompt_file) as f:
        prompt = f.read().strip()
    if tmux("list-windows", "-t", TMUX_SESSION, "-F", "#{window_name}").stdout.split().count(args.name):
        sys.exit(f"a window named {args.name!r} already exists in tmux session {TMUX_SESSION!r}")
    sid = str(uuid.uuid4())
    cmd = " ".join(shlex.quote(a) for a in ["claude", "-n", args.name, "--session-id", sid, prompt])
    cwd = os.path.expanduser(args.cwd)
    if tmux("has-session", "-t", TMUX_SESSION).returncode == 0:
        out = tmux("new-window", "-d", "-t", f"{TMUX_SESSION}:", "-n", args.name, "-c", cwd, cmd)
    else:
        out = tmux("new-session", "-d", "-s", TMUX_SESSION, "-n", args.name, "-c", cwd, cmd)
    if out.returncode != 0:
        sys.exit(f"tmux failed: {out.stderr}")
    rows = read_rows()
    rows.append({
        "datetime": datetime.datetime.now().strftime("%Y-%m-%d %H:%M"),
        "session": args.name,
        "id": sid,
        "status": "in-progress",
        "prompt": prompt,
        "notes": "",
    })
    write_rows(rows)
    print(f"id: {sid}\nwindow: {TMUX_SESSION}:{args.name}\nopen: {open_command(args.name)}")


def update(args):
    rows = read_rows()
    matches = [r for r in rows if args.name == r["session"] or r["id"].startswith(args.name)]
    if not matches:
        sys.exit(f"no delegate named {args.name!r}")
    row = matches[-1]
    row["status"] = args.status
    if args.notes is not None:
        row["notes"] = args.notes
    write_rows(rows)
    print(f"{row['session']} ({row['id']}): {row['status']}")


def list_rows(_):
    for r in read_rows():
        note = f"  [{r['notes']}]" if r["notes"] else ""
        print(f"{r['datetime']}  {r['status']:<11}  {r['session']} ({r['id']}){note}")


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(required=True)
    s = sub.add_parser("start")
    s.add_argument("--name", required=True)
    s.add_argument("--prompt-file", required=True)
    s.add_argument("--cwd", default="~/personal")
    s.set_defaults(fn=start)
    u = sub.add_parser("update")
    u.add_argument("--name", required=True, help="session name or id")
    u.add_argument("--status", required=True, choices=STATUSES)
    u.add_argument("--notes")
    u.set_defaults(fn=update)
    sub.add_parser("list").set_defaults(fn=list_rows)
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
