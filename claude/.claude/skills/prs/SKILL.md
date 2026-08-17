---
name: prs
description: Review a PR stack as a single combined change, from a link to the topmost PR to include — usually the tip, but a mid-stack link caps the review there. Walks the stack down to the base branch and reviews the cumulative diff as one unit (feature description, prioritized issues with BLOCKERS first, then review of existing comments across all PRs). Intermediate states between PRs are ignored — the stack ships as a whole. Read-only by default — findings go to the conversation, nothing is posted unless "write mode" is passed.
argument-hint: "<topmost PR link to review> [write mode]"
allowed-tools:
---

# prs - PR Stack Review

Review the stack of pull requests from the PR linked in `$ARGUMENTS` down to
the base branch, **as a single combined change**. The stack ships as a whole:
what matters is the cumulative diff from the base branch to the linked PR's
head, not any intermediate state between PRs. Use `gh` (or `glab` for GitLab)
to fetch metadata, diffs, and the full content of changed files for context.
If no link was given, ask for one.

## Discovering the stack

Starting from the linked PR, walk down the stack:

1. Fetch the linked PR's `baseRefName` and `headRefName`
   (`gh pr view <url> --json number,title,baseRefName,headRefName,url`).
2. Find the open PR whose head branch equals that base branch
   (`gh pr list --head <base-branch> --json ...`). That PR is the next one
   down the stack.
3. Repeat until the base branch is the repo's default branch (or no PR has it
   as a head branch).

If a stacking tool (Graphite, spr, etc.) lists the stack in the PR body, use
it to cross-check, but trust the branch topology. Before reviewing, print the
discovered stack in order (bottom → top) with PR numbers and titles so the
user can spot a mis-detected stack.

The linked PR is the top of the review scope. If PRs exist above the link
(some PR uses its head branch as a base), mention them in one line in case
the user linked the wrong PR, but do not review them — linking mid-stack is a
deliberate way to cap the review.

## The combined diff

Review the cumulative diff from the bottom PR's base branch to the linked
PR's head branch (`git diff <base>...<head>` on fetched branches, or the
equivalent via `gh`). This is the only diff that gets reviewed.

Do NOT review PRs individually, and do NOT report on intermediate states:
an issue introduced by one PR and fixed by a later one in the stack does not
exist — never mention it. Whether the stack is broken between merges is out
of scope.

The per-PR breakdown is used for only two things: describing how the work is
organized, and attributing findings to the PR where the fix belongs.

## Modes

- **Default (read-only):** ALL findings are reported inline in the
  conversation. Do not post, comment, approve, or reply to anything on any PR.
- **Write mode:** only if `$ARGUMENTS` contains "write mode" (or the user
  explicitly says otherwise in the conversation) may you post review comments
  and reply to existing comment threads — each finding on the PR where its
  fix belongs.

If you are unsure of anything or need clarification at any point, ask the user
in the conversation — never ask via PR comments, even in write mode.

## Phase 1 — Code review (code only)

Read the combined diff and surrounding code only. Do NOT read PR comments yet
— they would bias the review.

1. **Feature description.** Describe what the stack as a whole does: the new
   feature/change, its purpose, and how it's implemented at a high level.
   Include a one-line-per-PR note of how the work is split across the stack.

2. **Issues, categorized by priority.** List every issue found in the final
   state, grouped into priority categories, highest first:
   - **BLOCKERS** — the highest category. Include ONLY issues that must be
     fixed before merge (bugs, data loss, security holes, broken behavior).
     Nothing stylistic or speculative belongs here.
   - **HIGH** — should be fixed, but wouldn't stop the merge on its own.
   - **MEDIUM** — worth fixing; improvements and robustness gaps.
   - **LOW** — nits, style, naming, minor cleanups.

   Every issue must include:
   - Where it is (`file:line`) and what's wrong.
   - Which PR in the stack the fix belongs to.
   - A **proposed fix** — concrete, ideally with a code sketch.
   - The **complexity of that fix** (e.g. trivial / small / medium / large).

   Omit empty categories rather than writing "none".

## Phase 2 — Review the existing comments

Only after Phase 1 is complete, fetch the existing comments and review
threads from all PRs in scope — both from human colleagues and from
code-review bots.

Skip resolved threads entirely — do not review, summarize, or mention them.
Note that thread resolution is not in `gh pr view --json comments`; get
`isResolved` per thread from the GraphQL API (`gh api graphql` querying the
pull request's `reviewThreads`).

Review the remaining comments themselves: for each substantive comment, state whether
you agree or disagree and why, whether it's already addressed anywhere in the
stack, whether it's a false positive (common with bots), and what you'd
recommend the author do about it. Note any comment that overlaps with a
Phase 1 finding.

Report this comment review to the user in the conversation, same as Phase 1.
Do not reply on the PR threads unless in write mode.

## Write mode posting

When (and only when) write mode is active, after presenting both phases in
the conversation you may also post to the PRs: inline review comments for
Phase 1 issues on the PR where the fix belongs, and replies to the existing
threads reviewed in Phase 2 on their own PRs. Keep posted comments concise
and actionable. Clarifying questions still go to the user in the
conversation, never to any PR.
