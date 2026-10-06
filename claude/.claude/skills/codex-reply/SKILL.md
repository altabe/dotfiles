---
name: codex-reply
description: Handle Codex (or any other AI bot) review comments on a GitHub PR in a loop — push one commit of warranted fixes, reply concisely to every thread with the fix or a pushback, resolve them all, and wait for the next review. Finishes when Codex approves with a 👍 on the PR body.
argument-hint: "[PR link or number]"
allowed-tools:
---

# codex-reply - Address AI review comments until approval

The PR is given in `$ARGUMENTS` as a link or number. If none was given, use
the PR of the current branch (`gh pr view`). If there is none, ask.

## Philosophy — read this first

Favor readable, concise, maintainable code over robustness to every
imaginable edge case. Bots flag hypotheticals endlessly, and fixing each one
breeds new comments on the fix — a cascade that bloats the PR out of
proportion to its purpose. So **lean towards pushing back** whenever that's
reasonable.

- **Fix** real bugs, broken behavior, security issues, and cheap wins that
  make the code clearer. Keep fixes minimal — no new abstractions, config
  knobs or defensive layers to satisfy a bot.
- **Push back** on speculative edge cases, defensive checks for states that
  can't happen in practice, scope creep, style preferences, and anything
  whose fix costs more complexity than the risk it removes.
- **Defer** valid-but-out-of-scope points (say where it belongs, e.g. a
  follow-up).
- Codex tags comments with priority badges (P0/P1/P2/...). Treat them as a
  hint, not a verdict: a P1 on an impossible state is still a pushback.

If a comment is genuinely ambiguous or a judgment call with real product
impact, ask the user in the conversation rather than guessing.

## Setup

```bash
gh pr view <pr> --json number,headRefName,url,headRepositoryOwner,headRepository
```

Make sure you're on the PR's head branch with a clean working tree
(`gh pr checkout <pr>`; if there are unrelated local changes, stop and ask)
and that it's up to date with the remote (`git pull --ff-only`).

## The loop

### 1. Fetch unresolved bot threads

```bash
gh api graphql -f query='query($owner:String!, $repo:String!, $number:Int!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$number) {
      reviewThreads(first:100) { nodes {
        id isResolved path line
        comments(first:20) { nodes { author { __typename login } body url } }
      } }
    }
  }
}' -f owner=<owner> -f repo=<repo> -F number=<number>
```

Keep threads that are unresolved and started by a bot (`__typename == "Bot"`
or login containing `codex`/`[bot]`). Leave human threads alone.

If there are none: check whether Codex has already approved — a `+1`
reaction on the PR body from a `*codex*` user that is newer than the head
commit (`gh api repos/<owner>/<repo>/issues/<n>/reactions`). If so, you're
done. Otherwise jump to step 4 and trigger a review.

### 2. Decide and fix

For each thread, read the code it points at and decide **fix / pushback /
defer** per the philosophy above. Apply all fixes locally, run the relevant
fast checks (tests/lint for touched code, if obvious how), then make
**one commit and one push** for the whole iteration — every push triggers a
new review, so never push piecemeal.

Record `since=$(date -u +%Y-%m-%dT%H:%M:%SZ)` right before pushing (or
before commenting `@codex review` in step 4).

### 3. Reply and resolve every thread

Reply to each thread, then resolve it — all of them, including pushbacks
and deferrals:

```bash
gh api graphql -f query='mutation($id:ID!, $body:String!) {
  addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$id, body:$body}) { clientMutationId }
  resolveReviewThread(input:{threadId:$id}) { clientMutationId }
}' -f id=<thread-id> -f body=<reply>
```

Replies are **concise** — one or two sentences:

- Fix: `Fixed in <short-sha>: <what changed>.`
- Pushback: `Not changing: <why, briefly>.` (e.g. "the caller always passes
  a non-empty list; a guard here would be dead code.")
- Deferral: `Deferring: <why / where it'll be handled>.`

### 4. Wait for the next review

If this iteration pushed nothing (only pushbacks/deferrals), Codex won't
re-review on its own — comment to trigger it:

```bash
gh pr comment <pr> --body "@codex review"
```

Then poll in the background (Bash with `run_in_background: true`; you'll be
re-invoked when it exits):

```bash
~/.claude/skills/codex-reply/scripts/wait_for_review.sh <owner>/<repo> <number> <since> [timeout-min=20]
```

It prints one of:

- `APPROVED` — Codex 👍'd the PR body. Done; go to the report.
- `REVIEWED` — a bot submitted a review. Go back to step 1. (If the review
  produced no new threads, read its body: a "no issues" summary counts as
  approval; otherwise trigger again.)
- `COMMENTED` — a bot posted a PR-level comment. Read it: often it's an
  error (usage limit, couldn't review, etc.) — handle it, typically by
  commenting `@codex review` again; if it's actual feedback, address it like
  a thread (reply in a PR comment, since there's nothing to resolve).
- `TIMEOUT` — nothing happened. Codex sometimes silently drops requests;
  comment `@codex review` with a fresh `since` and wait again. After two
  consecutive timeouts, stop and tell the user.

As a sanity cap, if you've done ~6 iterations without approval, stop and ask
the user whether to continue — the comments are probably cascading.

## Report

When done (or stopped), summarize in the conversation: number of
iterations, and per iteration the commits pushed and a one-line tally of
fixed / pushed back / deferred threads, with the pushback reasons listed so
the user can overrule any of them.
