#!/usr/bin/env python3
"""Launch a background Claude session and keep a CSV log of delegated tasks.

  delegate.py start --name NAME --prompt-file FILE [--cwd DIR]
  delegate.py update --name NAME --status STATUS [--notes TEXT]
  delegate.py list
"""
import argparse
import csv
import datetime
import os
import re
import subprocess
import sys

LOG = os.path.expanduser("~/personal/delegates.csv")
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


def start(args):
    with open(args.prompt_file) as f:
        prompt = f.read().strip()
    out = subprocess.run(
        ["claude", "--bg", "-n", args.name, prompt],
        cwd=os.path.expanduser(args.cwd),
        capture_output=True,
        text=True,
    )
    text = out.stdout + out.stderr
    m = re.search(r"backgrounded\s*·\s*([0-9a-f]+)", text)
    if out.returncode != 0 or not m:
        sys.exit(f"claude --bg failed (exit {out.returncode}):\n{text}")
    sid = m.group(1)
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
    print(f"id: {sid}\nattach: claude attach {sid}")


def update(args):
    rows = read_rows()
    matches = [r for r in rows if args.name in (r["session"], r["id"])]
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
