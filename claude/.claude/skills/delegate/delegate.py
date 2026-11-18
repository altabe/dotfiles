#!/usr/bin/env python3
"""Delegated Claude sessions: one tmux window each, grouped by delegating session,
logged in ~/personal/delegates.csv.

  delegate.py start --name NAME --prompt-file FILE [--cwd DIR] [--replaces OLD]
  delegate.py update [--name NAME] --status STATUS [--notes TEXT]   (no --name: this session)
  delegate.py list [--all]        open delegates, with idle time and context size
  delegate.py tree [--all]        same, as a tree under the delegating sessions
  delegate.py open NAME           print the command that opens its window
  delegate.py find WORDS...       existing delegates (any status) about these words
  delegate.py reopen NAME [--fresh] [--message TEXT]   (running: just hands it the message)
  delegate.py close NAME [--park] [--notes TEXT]
  delegate.py send (NAME... | --all | --children-of NAME) --message TEXT
  delegate.py sweep [--dry-run]   weekly: close done delegates, warn about long-idle ones
  delegate.py doctor              CSV vs reality
  delegate.py tick                run by keepalive: deliver queued messages, finish closes,
                                  sweep when a week has passed
  delegate.py keepalive-targets   lines "<tmux-session> <window> <cwd> <id>" to keep alive

Each delegate's window lives in the tmux session "d-<parent>", where <parent> is the
name of the session that delegated it, so nested delegation forms a tree.
"""
import argparse
import contextlib
import csv
import datetime
import fcntl
import glob
import json
import os
import re
import shlex
import subprocess
import sys
import time
import uuid

HOME = os.path.expanduser("~")
LOG = os.environ.get("DELEGATE_LOG", f"{HOME}/personal/delegates.csv")   # env: for tests
STATE_ROOT = f"{HOME}/personal/delegates"
RUN_DIR = os.environ.get("DELEGATE_RUN_DIR", f"{HOME}/.local/state/delegate")
SESSIONS_DIR = f"{HOME}/.claude/sessions"
PROJECTS_DIR = f"{HOME}/.claude/projects"
FIELDS = ["datetime", "session", "id", "status", "prompt", "notes", "cwd", "parent_id", "parent"]
STATUSES = ("in-progress", "waiting", "blocked", "done", "parked")
KEPT = ("in-progress", "waiting", "blocked")     # keepalive resumes these
PREFIX = "[delegate]"                             # marks automated messages; not activity
NOT_ACTIVITY = (PREFIX, "<", "/remote-control", "This session is being continued",
                "Tab cleanup (from Tomer, via the pa session)")   # last: 2026-11-18 broadcast
DONE_GRACE_H = 48                                 # done delegates close after this idle time
WARN_DAYS = 30                                    # unfinished delegates idle this long: warn
SWEEP_EVERY_D = 7
WRAPUP_TIMEOUT_MIN = 30
WRAPUP = (f"{PREFIX} You're being closed ({{why}}). Close the Chrome tabs you opened, "
          "except any Tomer asked to keep, and make STATE.md current, including what "
          "you're waiting on. Then reply only: ready to close")


# ---------- CSV ----------

@contextlib.contextmanager
def locked():
    os.makedirs(RUN_DIR, exist_ok=True)
    with open(f"{RUN_DIR}/csv.lock", "w") as lk:
        fcntl.flock(lk, fcntl.LOCK_EX)
        yield


def read_rows():
    if not os.path.exists(LOG):
        return []
    with open(LOG, newline="") as f:
        rows = list(csv.DictReader(f))
    for r in rows:
        for k in FIELDS:
            r[k] = r.get(k) or ""
        r["cwd"] = r["cwd"] or "~/personal"
    return rows


def write_rows(rows):
    tmp = LOG + ".tmp"
    with open(tmp, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS, extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)
    os.replace(tmp, LOG)


def find(rows, key):
    """Latest row whose name or id (prefix) matches."""
    m = [r for r in rows if key == r["session"] or (len(key) >= 6 and r["id"].startswith(key))]
    return m[-1] if m else None


def set_status(key, status, notes=None):
    with locked():
        rows = read_rows()
        r = find(rows, key)
        if not r:
            sys.exit(f"no delegate {key!r}")
        r["status"] = status
        if notes is not None:
            r["notes"] = notes
        write_rows(rows)
        return r


# ---------- live sessions, tmux, transcripts ----------

def tmux(*argv):
    return subprocess.run(["tmux", *argv], capture_output=True, text=True)


def live_sessions():
    """sessionId -> ~/.claude/sessions/<pid>.json of a running Claude process."""
    out = {}
    for f in glob.glob(f"{SESSIONS_DIR}/*.json"):
        try:
            d = json.load(open(f))
            os.kill(d["pid"], 0)
        except Exception:
            continue
        out[d.get("sessionId")] = d
    return out


def pane_of(info):
    """'delegates:@45.%48' -> '%48'."""
    t = (info or {}).get("tmux") or ""
    return t.rsplit(".", 1)[-1] if "%" in t else None


def tmux_name(name):
    return re.sub(r"[.:\s]", "-", name)


def group_of(row):
    return "d-" + tmux_name(row["parent"] or "pa")


def session_name(sid, rows=None):
    r = find(rows if rows is not None else read_rows(), sid) if sid else None
    if r and r["id"] == sid:
        return r["session"]
    info = live_sessions().get(sid)
    if info and info.get("name"):
        return info["name"]
    return sid[:8] if sid else "tomer"


ANSI = re.compile(r"\x1b\[[0-9;]*m")
DIM = re.compile(r"\x1b\[2m[^\x1b]*")
SPINNER = re.compile(r"… \((\d+[hms] ?)+")


def pane_ready(pane):
    """An empty input prompt is showing (dim suggestions don't count), no menu or
    dialog has the cursor, and no spinner is running."""
    out = tmux("capture-pane", "-p", "-e", "-t", pane)
    if out.returncode:
        return False
    lines = out.stdout.splitlines()
    prompts = [l for l in lines if "❯" in l]
    if not prompts:
        return False
    text = ANSI.sub("", DIM.sub("", prompts[-1])).split("❯", 1)[1]
    if text.replace("\xa0", "").strip():
        return False
    plain = [ANSI.sub("", l) for l in lines[-15:]]
    return not any(SPINNER.search(l) for l in plain)


def session_ready(info):
    pane = pane_of(info)
    return bool(pane) and info.get("status", "idle") == "idle" and pane_ready(pane)


def type_into(pane, text):
    tmux("send-keys", "-t", pane, "-l", text)
    time.sleep(0.5)
    tmux("send-keys", "-t", pane, "Enter")


def transcript(sid):
    f = glob.glob(f"{PROJECTS_DIR}/*/{sid}.jsonl")
    return f[0] if f else None


def _text(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(x.get("text", "") for x in content if isinstance(x, dict) and x.get("type") == "text")
    return ""


def activity(sid):
    """(last human message time, last assistant text, context tokens) from the transcript."""
    f = transcript(sid)
    if not f:
        return None, "", 0
    human, last_asst, tokens = None, "", 0
    for line in open(f, errors="ignore"):
        try:
            d = json.loads(line)
        except ValueError:
            continue
        t = d.get("type")
        if (t == "user" and not d.get("isMeta") and not d.get("toolUseResult")
                and not d.get("isCompactSummary") and (d.get("origin") or {}).get("kind") != "task-notification"):
            s = _text(d.get("message", {}).get("content")).strip()
            if s and not s.startswith(NOT_ACTIVITY):
                human = d.get("timestamp")
        elif t == "assistant":
            msg = d.get("message", {})
            s = _text(msg.get("content")).strip()
            if s:
                last_asst = s
            u = msg.get("usage") or {}
            n = sum(u.get(k, 0) for k in ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens"))
            tokens = n or tokens
    when = None
    if human:
        when = datetime.datetime.fromisoformat(human.replace("Z", "+00:00")).timestamp()
    else:
        when = os.path.getmtime(f)
    return when, last_asst, tokens


def ago(ts):
    if not ts:
        return "?"
    s = time.time() - ts
    return f"{s / 86400:.0f}d" if s >= 86400 else f"{s / 3600:.0f}h"


# ---------- queued messages and closes (state in RUN_DIR) ----------

def load(name, default):
    try:
        return json.load(open(f"{RUN_DIR}/{name}.json"))
    except Exception:
        return default


def save(name, data):
    os.makedirs(RUN_DIR, exist_ok=True)
    tmp = f"{RUN_DIR}/{name}.json.tmp"
    json.dump(data, open(tmp, "w"), indent=1)
    os.replace(tmp, f"{RUN_DIR}/{name}.json")


def deliver(sid, text, live=None):
    """Type text into session sid now if it's safe, else queue it. Returns 'sent'/'queued'/'not running'."""
    live = live if live is not None else live_sessions()
    info = live.get(sid)
    if info and session_ready(info):
        type_into(pane_of(info), text)
        return "sent"
    q = load("outbox", [])
    q.append({"id": sid, "text": text, "queued": time.time()})
    save("outbox", q)
    return "queued" if info else "not running, queued"


def flush_outbox(live):
    keep = []
    for m in load("outbox", []):
        info = live.get(m["id"])
        if info and session_ready(info):
            type_into(pane_of(info), m["text"])
            info["status"] = "busy"           # one message per session per run
        elif time.time() - m["queued"] < 3 * 86400:
            keep.append(m)
    save("outbox", keep)


def begin_close(row, final, notes, why, live):
    closing = load("closing", {})
    info = live.get(row["id"])
    if not info:                               # not running: nothing to wrap up
        set_status(row["id"], final, notes)
        return "closed (was not running)"
    sent = None
    if session_ready(info):
        type_into(pane_of(info), WRAPUP.format(why=why))
        sent = time.time()
    closing[row["id"]] = {"name": row["session"], "final": final, "notes": notes, "why": why, "sent": sent}
    save("closing", closing)
    return "wrap-up sent" if sent else "wrap-up queued (pane busy)"


def finish_closes(live):
    closing = load("closing", {})
    for sid, c in list(closing.items()):
        info = live.get(sid)
        if not info:
            set_status(sid, c["final"], c["notes"])
            del closing[sid]
            continue
        if not session_ready(info):
            continue
        if not c["sent"]:
            type_into(pane_of(info), WRAPUP.format(why=c["why"]))
            c["sent"] = time.time()
            continue
        _, last, _ = activity(sid)
        if "ready to close" in last.lower() or time.time() - c["sent"] > WRAPUP_TIMEOUT_MIN * 60:
            set_status(sid, c["final"], c["notes"])    # before /exit, so keepalive won't revive it
            type_into(pane_of(info), "/exit")
            del closing[sid]
    save("closing", closing)


# ---------- commands ----------

def launch(name, sid, cwd, group, claude_args):
    cmd = " ".join(shlex.quote(a) for a in ["claude", "-n", name, *claude_args])
    cmd = f"zsh -ic {shlex.quote(cmd)}"      # .zshrc: usual PATH and claude alias
    cwd = os.path.expanduser(cwd)
    if tmux("has-session", "-t", f"={group}").returncode == 0:
        out = tmux("new-window", "-d", "-t", f"={group}:", "-n", name, "-c", cwd, cmd)
    else:
        out = tmux("new-session", "-d", "-s", group, "-n", name, "-c", cwd, cmd)
    if out.returncode:
        sys.exit(f"tmux failed: {out.stderr}")


def open_command(row):
    t = f"={group_of(row)}:{row['session']}"
    return f"tmux switch-client -t '{t}' 2>/dev/null || tmux attach -t '{t}'"


def start(a):
    prompt = open(a.prompt_file).read().strip()
    with locked():
        rows = read_rows()
        old = find(rows, a.replaces) if a.replaces else None
        if a.replaces and not old:
            sys.exit(f"no delegate {a.replaces!r}")
        # A handoff takes the old delegate's place in the tree.
        parent_id = a.parent_id or (old and old["parent_id"]) or os.environ.get("CLAUDE_CODE_SESSION_ID", "")
        if any(r["session"] == a.name and r["status"] in KEPT for r in rows):
            sys.exit(f"an open delegate is already named {a.name!r}")
        row = {"datetime": datetime.datetime.now().strftime("%Y-%m-%d %H:%M"), "session": a.name,
               "id": str(uuid.uuid4()), "status": "in-progress", "prompt": prompt, "notes": "",
               "cwd": a.cwd, "parent_id": parent_id, "parent": session_name(parent_id, rows)}
        launch(a.name, row["id"], a.cwd, group_of(row), ["--session-id", row["id"], prompt])
        rows.append(row)
        write_rows(rows)
    print(f"id: {row['id']}\nwindow: {group_of(row)}:{a.name}\nopen: {open_command(row)}")
    if old:
        print(f"{old['session']}: " + begin_close(old, "done", f"handed off to {a.name}",
                                                      f"handed off to {a.name}", live_sessions()))


def update(a):
    key = a.name or os.environ.get("CLAUDE_CODE_SESSION_ID")
    if not key:
        sys.exit("--name is required outside a Claude session")
    r = set_status(key, a.status, a.notes)
    print(f"{r['session']} ({r['id']}): {r['status']}")


def rows_view(show_all):
    rows = read_rows()
    live = live_sessions()
    out = []
    for r in rows:
        if not show_all and r["status"] not in KEPT and r["id"] not in live:
            continue
        when, _, tok = activity(r["id"]) if r["status"] in KEPT or r["id"] in live else (None, "", 0)
        r["_idle"] = ago(when) if when else "-"
        r["_ctx"] = f"{tok // 1000}k" if tok else "-"
        r["_live"] = r["id"] in live
        out.append(r)
    return out


def fmt(r):
    flag = "" if r["_live"] or r["status"] not in KEPT else "  (not running)"
    note = f"  — {r['notes']}" if r["notes"] else ""
    return f"{r['session']}  [{r['status']}, idle {r['_idle']}, ctx {r['_ctx']}]{flag}{note}"


def list_rows(a):
    for r in rows_view(a.all):
        print(f"{r['parent'] or '?':<14} {fmt(r)}")


def tree(a):
    rows = rows_view(a.all)
    ids = {r["id"] for r in rows}
    kids = {}
    for r in rows:
        kids.setdefault(r["parent_id"] if r["parent_id"] in ids else "root:" + (r["parent"] or "?"), []).append(r)

    def walk(key, depth):
        for r in kids.get(key, []):
            print("  " * depth + "- " + fmt(r))
            walk(r["id"], depth + 1)
    for key in [k for k in kids if k.startswith("root:")]:
        print(key[5:])
        walk(key, 1)


def open_(a):
    r = find(read_rows(), a.name) or sys.exit(f"no delegate {a.name!r}")
    info = live_sessions().get(r["id"])
    if info and pane_of(info):
        t = pane_of(info)
        print(f"tmux switch-client -t '{t}' 2>/dev/null || tmux attach -t '{t}'")
    else:
        print(f"not running; reopen with: delegate.py reopen {r['session']}")


def reopen(a):
    """Bring a delegate back (or reach it if it's running) and optionally hand it a request."""
    msg = " ".join(a.message.split()) if a.message else None
    with locked():
        rows = read_rows()
        r = find(rows, a.name) or sys.exit(f"no delegate {a.name!r}")
        if r["id"] in live_sessions():
            if not msg:
                sys.exit(f"{r['session']} is already running: " + open_command(r))
            r["status"] = "in-progress"
            write_rows(rows)
            fresh_prompt = None
        elif a.fresh:
            old = r["id"]
            r["id"] = str(uuid.uuid4())
            r["notes"] = f"fresh session; previous id {old}. " + r["notes"]
            fresh_prompt = (f"Continue the task in ~/personal/delegates/{r['session']}/: read STATE.md "
                            "there first and continue from it. Keep STATE.md current as before."
                            + (f"\n\nNew request from Tomer: {msg}" if msg else "")
                            + "\nnotify me when the task is done")
            r["status"] = "in-progress"
            launch(r["session"], r["id"], r["cwd"], group_of(r), ["--session-id", r["id"], fresh_prompt])
            write_rows(rows)
        else:
            fresh_prompt = None
            r["status"] = "in-progress"
            launch(r["session"], r["id"], r["cwd"], group_of(r), ["--resume", r["id"]])
            write_rows(rows)
    print(f"{r['session']}: in-progress\nopen: {open_command(r)}")
    if msg and not fresh_prompt:
        # A resumed session takes a few seconds to show its prompt; wait for it, else queue.
        text = f"New request from Tomer: {msg}"
        for _ in range(30):
            info = live_sessions().get(r["id"])
            if info and session_ready(info):
                break
            time.sleep(3)
        print("request: " + deliver(r["id"], text))


STOP = set("a an and the of for to in on with my me i is it this that be by at from or as".split())


def stem(w):
    return w[:max(4, len(w) - 2)] if len(w) > 4 else w


def search(a):
    """Rank delegates (latest row per name, any status) by how many query words they mention."""
    words = [w for w in re.findall(r"[\w-]+", " ".join(a.words).lower()) if w not in STOP]
    latest = {}
    for r in read_rows():
        latest[r["session"]] = r
    live = live_sessions()
    hits = []
    me = os.environ.get("CLAUDE_CODE_SESSION_ID")
    for r in latest.values():
        if r["id"] == me:
            continue
        goal = ""
        st = f"{STATE_ROOT}/{r['session']}/STATE.md"
        if os.path.exists(st):
            text = open(st, errors="ignore").read()
            m = re.search(r"^##[^\n]*goal[^\n]*\n(.*?)(?=^## )", text, re.S | re.I | re.M)
            goal = m.group(1) if m else text[:1500]
        hay = " ".join([r["prompt"], r["notes"], goal]).lower()
        name = r["session"].replace("-", " ")
        pats = [re.compile(r"\b" + re.escape(stem(w))) for w in words]
        score = sum(bool(p.search(hay) or p.search(name)) for p in pats)
        named = sum(bool(p.search(name)) for p in pats)          # name matches rank first
        if score * 2 >= len(words):                               # at least half the words
            hits.append((score, named, r))
    hits.sort(key=lambda h: (-(h[0] + h[1]), -h[0]))
    hits = [(sc, r) for sc, _, r in hits]
    print(f"matches for {' '.join(words)!r}:" if hits else "no matches")
    for score, r in hits[:8]:
        state = "running" if r["id"] in live else "not running"
        print(f"  {score}/{len(words)}  {r['session']}  [{r['status']}, {state}]  {r['notes'][:100]}")
    shown = {r["session"] for _, r in hits[:8]}
    rest = [r for r in latest.values() if r["status"] in KEPT and r["session"] not in shown]
    if rest:
        print("other open delegates (check by meaning, not just words):")
        for r in rest:
            print(f"  {r['session']}  [{r['status']}]  {r['notes'][:100]}")


def close(a):
    r = find(read_rows(), a.name) or sys.exit(f"no delegate {a.name!r}")
    final = "parked" if a.park else "done"
    print(f"{r['session']}: " + begin_close(r, final, a.notes if a.notes is not None else r["notes"],
                                            "parked by Tomer" if a.park else "task done", live_sessions()))


def send(a):
    rows = read_rows()
    if a.all:
        targets = [r for r in rows if r["status"] in KEPT]
    elif a.children_of:
        p = find(rows, a.children_of)
        pid = p["id"] if p else None
        targets = [r for r in rows if r["status"] in KEPT and (r["parent_id"] == pid or r["parent"] == a.children_of)]
    else:
        targets = [find(rows, n) or sys.exit(f"no delegate {n!r}") for n in a.names]
    text = f"{PREFIX} " + " ".join(a.message.split())   # one line: a newline would submit early
    live = live_sessions()
    for r in targets:
        print(f"{r['session']}: {deliver(r['id'], text, live)}")


def sweep(a):
    rows = read_rows()
    live = live_sessions()
    closing = load("closing", {})
    warn, closed = {}, {}
    for r in rows:
        if r["id"] in closing:
            continue
        running = r["id"] in live
        if r["status"] in ("done", "parked") and not running:
            continue
        when, _, _ = activity(r["id"])
        idle_h = (time.time() - when) / 3600 if when else 0
        if r["status"] == "done" and idle_h >= DONE_GRACE_H:
            msg = begin_close(r, "done", r["notes"], "task done", live) if not a.dry_run else "would close"
            print(f"{r['session']}: done, idle {ago(when)}: {msg}")
            closed.setdefault(r["parent_id"], []).append(r["session"])
        elif r["status"] in KEPT and idle_h >= WARN_DAYS * 24:
            warn.setdefault(r["parent_id"], []).append(f"{r['session']} ({r['status']}, idle {ago(when)}"
                                                       + (f", {r['notes']}" if r["notes"] else "") + ")")
    by_id = {r["id"]: r for r in rows}
    for pid in {**closed, **warn}:
        items = warn.get(pid, [])
        text = f"{PREFIX} Weekly delegate sweep."
        if closed.get(pid):
            text += (f" Closed because they marked themselves done: {', '.join(closed[pid])}"
                     " (tell Tomer; `delegate.py reopen <name>` if one wasn't really done).")
        if items:
            text += (f" These delegates of yours have had no message from Tomer in {WARN_DAYS}+ days: "
                     f"{'; '.join(items)}. Ask Tomer whether to keep each one, park it "
                     "(delegate.py close <name> --park) or mark it done (delegate.py close <name>).")
        target = pid                             # nearest running ancestor
        while target and target not in live:
            target = by_id.get(target, {}).get("parent_id")
        print(f"report to {session_name(pid, rows)}: {text}")
        if a.dry_run:
            continue
        if target:
            print("  → " + deliver(target, text, live) + f" to {session_name(target, rows)}")
        else:
            with open(f"{STATE_ROOT}/sweep-report.md", "a") as f:
                f.write(f"- {datetime.date.today()}: {text}\n")
            print(f"  → no running ancestor; appended to {STATE_ROOT}/sweep-report.md")
    if not a.dry_run:
        save("last-sweep", {"at": time.time()})


def doctor(_):
    rows = read_rows()
    live = live_sessions()
    by_id = {r["id"]: r for r in rows}
    for r in rows:
        if r["status"] in KEPT and r["id"] not in live:
            print(f"{r['session']}: {r['status']} but not running (keepalive should resume it)")
        if r["status"] in ("done", "parked") and r["id"] in live and r["id"] not in load("closing", {}):
            print(f"{r['session']}: {r['status']} but still running (sweep closes done ones after {DONE_GRACE_H}h)")
        info = live.get(r["id"])
        if info and info.get("name") and info["name"] != r["session"]:
            print(f"{r['session']}: running under another name, {info['name']!r}")
        if not transcript(r["id"]) and r["status"] in KEPT:
            print(f"{r['session']}: no transcript found for {r['id']}")
    for sid, info in live.items():
        t = info.get("tmux") or ""
        if t.startswith("d-") and sid not in by_id:
            print(f"{info.get('name')} ({sid}) runs in {t} but has no row in the log")


def tick(_):
    live = live_sessions()
    flush_outbox(live)
    finish_closes(live)
    if time.time() - load("last-sweep", {}).get("at", 0) >= SWEEP_EVERY_D * 86400:
        sweep(argparse.Namespace(dry_run=False))


def keepalive_targets(_):
    for r in read_rows():
        if r["status"] in KEPT and re.fullmatch(r"[0-9a-f-]{36}", r["id"]):
            print(group_of(r), tmux_name(r["session"]), r["cwd"], r["id"])


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(required=True)
    s = sub.add_parser("start")
    s.add_argument("--name", required=True)
    s.add_argument("--prompt-file", required=True)
    s.add_argument("--cwd", default="~/personal")
    s.add_argument("--parent-id", help="default: this Claude session")
    s.add_argument("--replaces", help="close this delegate as handed off")
    s.set_defaults(fn=start)
    s = sub.add_parser("update")
    s.add_argument("--name", help="session name or id; default: this session")
    s.add_argument("--status", required=True, choices=STATUSES)
    s.add_argument("--notes")
    s.set_defaults(fn=update)
    for n, fn in (("list", list_rows), ("tree", tree)):
        s = sub.add_parser(n)
        s.add_argument("--all", action="store_true")
        s.set_defaults(fn=fn)
    s = sub.add_parser("open")
    s.add_argument("name")
    s.set_defaults(fn=open_)
    s = sub.add_parser("reopen")
    s.add_argument("name")
    s.add_argument("--fresh", action="store_true", help="new session that continues from STATE.md")
    s.add_argument("--message", help="request to hand it once it's up (works if it's running too)")
    s.set_defaults(fn=reopen)
    s = sub.add_parser("find")
    s.add_argument("words", nargs="+")
    s.set_defaults(fn=search)
    s = sub.add_parser("close")
    s.add_argument("name")
    s.add_argument("--park", action="store_true", help="not finished: status parked instead of done")
    s.add_argument("--notes")
    s.set_defaults(fn=close)
    s = sub.add_parser("send")
    s.add_argument("names", nargs="*")
    g = s.add_mutually_exclusive_group()
    g.add_argument("--all", action="store_true")
    g.add_argument("--children-of")
    s.add_argument("--message", required=True)
    s.set_defaults(fn=send)
    s = sub.add_parser("sweep")
    s.add_argument("--dry-run", action="store_true")
    s.set_defaults(fn=sweep)
    for n, fn in (("doctor", doctor), ("tick", tick), ("keepalive-targets", keepalive_targets)):
        sub.add_parser(n).set_defaults(fn=fn)
    a = p.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
