---
name: pr
description: Review a GitHub/GitLab PR from its link. Describes the feature, lists prioritized issues (BLOCKERS first) with proposed fixes, then reviews the existing PR comments themselves. Read-only by default — findings go to the conversation, nothing is posted to the PR unless "write mode" is passed.
argument-hint: "<PR link> [write mode]"
allowed-tools:
---

# pr - PR Review

Review the pull request at the link given in `$ARGUMENTS`. Use `gh` (or `glab`
for GitLab) to fetch the PR metadata, diff, and the full content of changed
files for context. If no link was given, ask for one.

## Modes

- **Default (read-only):** ALL findings are reported inline in the conversation.
  Do not post, comment, approve, or reply to anything on the PR.
- **Write mode:** only if `$ARGUMENTS` contains "write mode" (or the user
  explicitly says otherwise in the conversation) may you post review comments
  and reply to existing comment threads on the PR.

If you are unsure of anything or need clarification at any point, ask the user
in the conversation — never ask via PR comments, even in write mode.

## Phase 1 — Code review (code only)

Read the diff and surrounding code only. Do NOT read PR comments yet — they
would bias the review.

1. **Feature description.** Start the review by describing what the PR does:
   the new feature/change, its purpose, and how it's implemented at a high
   level.

2. **Issues, categorized by priority.** List every issue found, grouped into
   priority categories, highest first:
   - **BLOCKERS** — the highest category. Include ONLY issues that must be
     fixed before merge (bugs, data loss, security holes, broken behavior).
     Nothing stylistic or speculative belongs here.
   - **HIGH** — should be fixed, but wouldn't stop the merge on its own.
   - **MEDIUM** — worth fixing; improvements and robustness gaps.
   - **LOW** — nits, style, naming, minor cleanups.

   Every issue must include:
   - Where it is (`file:line`) and what's wrong.
   - A **proposed fix** — concrete, ideally with a code sketch.
   - The **complexity of that fix** (e.g. trivial / small / medium / large).

   Omit empty categories rather than writing "none".

## Phase 2 — Review the existing comments

Only after Phase 1 is complete, fetch the PR's existing comments and review
threads — both from human colleagues and from code-review bots.

Review the comments themselves: for each substantive comment, state whether
you agree or disagree and why, whether it's already addressed, whether it's a
false positive (common with bots), and what you'd recommend the PR author do
about it. Note any comment that overlaps with a Phase 1 finding.

Report this comment review to the user in the conversation, same as Phase 1.
Do not reply on the PR threads unless in write mode.

## Write mode posting

When (and only when) write mode is active, after presenting both phases in the
conversation you may also post to the PR: inline review comments for the Phase
1 issues and replies to the existing threads reviewed in Phase 2. Keep posted
comments concise and actionable. Clarifying questions still go to the user in
the conversation, never to the PR.
