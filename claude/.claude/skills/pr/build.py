#!/usr/bin/env python3
"""Render a /pr review into its artifact page, and record decisions on it.

    build.py REVIEW_JSON
        Checks REVIEW_JSON and writes the page beside it (same name, .html).

    build.py REVIEW_JSON --decide ID ACTION --outcome TEXT [--note TEXT] [--failed]
        Records the decision on item ID (an issue or a comment), then writes the page.
        ACTION is accept, assess, ask, suggest, defer or deny. --failed marks an attempt that did
        not go through: the page shows the outcome and offers the choices again. An ask is
        never a decision: its outcome is the answer, and the choices stay open.

    build.py REVIEW_JSON --session NAME
        Records the implementing session the last decision was routed to ("" clears it),
        so the page starts with it on another device. Combines with --decide.

The page template is review.html beside this script. See SKILL.md for the JSON shape.
"""

from __future__ import annotations

import argparse
import html
import json
import sys
from datetime import UTC, datetime
from pathlib import Path

TEMPLATE = Path(__file__).with_name("review.html")
ACTIONS = ("accept", "assess", "ask", "suggest", "defer", "deny")
PRIORITIES = ("blocker", "high", "medium", "low")
ROLES = ("author", "reviewer")


def problems(data: dict) -> list[str]:
    found: list[str] = []
    pr = data.get("pr")
    if not isinstance(pr, dict):
        return ["pr: missing"]
    for key in ("title", "url", "repo", "number", "role"):
        if key not in pr:
            found.append(f"pr.{key}: missing")
    if pr.get("role") not in ROLES:
        found.append(f"pr.role: must be one of {ROLES}")
    if not str(pr.get("url", "")).startswith("https://"):
        found.append("pr.url: must be an https:// link")
    if not isinstance(data.get("summary"), str):
        found.append("summary: missing")
    seen: set[str] = set()
    for index, item in enumerate(data.get("issues", [])):
        where = f"issues[{index}]"
        for key in ("id", "priority", "title", "body", "fix", "complexity"):
            if not item.get(key):
                found.append(f"{where}.{key}: missing")
        if item.get("priority") not in PRIORITIES:
            found.append(f"{where}.priority: must be one of {PRIORITIES}")
        if not isinstance(item.get("where", []), list):
            found.append(f"{where}.where: must be a list of path:line strings")
        found += _id(item, where, seen)
    for index, item in enumerate(data.get("comments", [])):
        where = f"comments[{index}]"
        for key in ("id", "author", "assessment", "recommendation"):
            if not item.get(key):
                found.append(f"{where}.{key}: missing")
        found += _id(item, where, seen)
    lines = data.get("lines")
    if lines is not None:
        if not isinstance(lines.get("rows"), list) or not lines.get("surface"):
            found.append("lines: needs rows and surface")
    for kind in ("issues", "comments"):
        for item in data.get(kind, []):
            decision = item.get("decision")
            if decision and decision.get("action") not in ACTIONS:
                found.append(f"{item.get('id')}.decision.action: must be one of {ACTIONS}")
    return found


def _id(item: dict, where: str, seen: set[str]) -> list[str]:
    ident = str(item.get("id", ""))
    if not ident.replace("-", "").isalnum():
        return [f"{where}.id: letters, digits and hyphens only"]
    if ident in seen:
        return [f"{where}.id: {ident} is used twice"]
    seen.add(ident)
    return []


def render(data: dict, out: Path) -> None:
    pr = data["pr"]
    repo_name = str(pr["repo"]).rsplit("/", 1)[-1]
    title = f"{repo_name} #{pr['number']} review"
    payload = json.dumps(data, ensure_ascii=False, indent=1).replace("<", "\\u003c")
    page = TEMPLATE.read_text(encoding="utf-8")
    page = page.replace("__TITLE__", html.escape(title), 1).replace("__REVIEW_JSON__", payload, 1)
    out.write_text(page, encoding="utf-8")


def decide(data: dict, ident: str, action: str, outcome: str, note: str | None, failed: bool) -> None:
    for kind in ("issues", "comments"):
        for item in data.get(kind, []):
            if item.get("id") == ident:
                now = datetime.now(UTC)
                item["decision"] = {
                    "action": action,
                    "note": note or None,
                    "outcome": outcome,
                    "status": "failed" if failed else "answered" if action == "ask" else "done",
                    "at": now.strftime("%Y-%m-%d %H:%M UTC"),
                    # Epoch ms: the page compares it with when its viewer sent a decision.
                    "ts": int(now.timestamp() * 1000),
                }
                return
    raise SystemExit(f"no issue or comment with id {ident!r}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("review", type=Path)
    parser.add_argument("--decide", nargs=2, metavar=("ID", "ACTION"))
    parser.add_argument("--outcome", help="what was done, in light Markdown")
    parser.add_argument("--note", help="the note that came with the decision")
    parser.add_argument("--failed", action="store_true")
    parser.add_argument("--session", help='the implementing session decisions go to; "" clears it')
    args = parser.parse_args()

    data = json.loads(args.review.read_text(encoding="utf-8"))
    changed = bool(args.decide) or args.session is not None
    if args.session is not None:
        name = " ".join(args.session.split())[:120]
        if name:
            data["implementing_session"] = name
        else:
            data.pop("implementing_session", None)
    if args.decide:
        ident, action = args.decide
        if action not in ACTIONS:
            raise SystemExit(f"ACTION must be one of {ACTIONS}")
        if not args.outcome:
            raise SystemExit("--decide needs --outcome")
        decide(data, ident, action, args.outcome, args.note, args.failed)
    found = problems(data)
    if found:
        print("review.json has problems:", *found, sep="\n  ", file=sys.stderr)
        raise SystemExit(1)
    if changed:
        args.review.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    out = args.review.with_suffix(".html")
    render(data, out)
    items = data.get("issues", []) + data.get("comments", [])
    decided = sum(1 for item in items if (item.get("decision") or {}).get("status") == "done")
    print(f"{out}  ({decided} of {len(items)} decided)")


if __name__ == "__main__":
    main()
