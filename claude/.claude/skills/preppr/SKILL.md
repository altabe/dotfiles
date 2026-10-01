---
name: preppr
description: Prep a GitHub PR for review by marking uninteresting files as viewed. Uninteresting = files under tests/docs dirs, moved/renamed files, or files whose entire diff is only renames, import fixes, or comment changes. Reports what was marked and why, leaving only the files worth reviewing.
argument-hint: "[PR link or number]"
allowed-tools:
---

# preppr - Prep PR for Review

Mark the uninteresting files of a pull request as "viewed" on GitHub, so the
reviewer's file list collapses down to only the files that actually need
attention.

The PR is given in `$ARGUMENTS` as a link or number. If none was given, use
the PR associated with the current branch (`gh pr view`). If there is none,
ask the user for one.

## Step 1 — Fetch the PR

Use `gh` to fetch the list of changed files and the full diff:

```bash
gh pr view <pr> --json files,headRepository,number
gh pr diff <pr>
```

Also fetch rename/move information, which `gh pr diff` shows as
`rename from` / `rename to` lines (or use
`gh api repos/{owner}/{repo}/pulls/{number}/files --paginate` where
`status: "renamed"` and `previous_filename` identify moves).

## Step 2 — Classify each file

A file is **uninteresting** if it matches ANY of:

1. **Tests or docs directory** — its path contains a tests or docs directory
   segment (e.g. `tests/`, `test/`, `__tests__/`, `docs/`, `doc/`).
2. **Moved file** — the file was renamed/moved with no content change, or
   only trivial changes caused by the move itself (e.g. updated relative
   imports within the moved file).
3. **Only trivial changes** — EVERY changed hunk in the file falls into one
   of these categories (a single substantive hunk makes the whole file
   interesting):
   - **Renames** — an identifier/symbol/string was renamed consistently
     (function, class, variable, module name), with no logic change.
   - **Import fixes** — added/removed/reordered/re-pathed import or include
     statements, usually fallout from a rename or move elsewhere in the PR.
   - **Comments** — changes only to comments or docstrings.

Judge from the actual diff hunks, not the filename alone (except for rule 1,
which is purely path-based). Be conservative: if a hunk could plausibly
change behavior, the file is interesting — when in doubt, do NOT mark it.

## Step 3 — Mark as viewed

Marking files as viewed requires the GraphQL API. First get the PR node id:

```bash
gh api graphql -f query='query($owner:String!, $repo:String!, $number:Int!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$number) { id }
  }
}' -f owner=<owner> -f repo=<repo> -F number=<number>
```

Then for each uninteresting file:

```bash
gh api graphql -f query='mutation($prId:ID!, $path:String!) {
  markFileAsViewed(input:{pullRequestId:$prId, path:$path}) {
    pullRequest { id }
  }
}' -f prId=<pr-node-id> -f path=<file-path>
```

Batch multiple files into one GraphQL request with aliases when there are
many (e.g. `f0: markFileAsViewed(...) { clientMutationId } f1: ...`).

Note: viewed state is per-user, so this marks them for the account `gh` is
authenticated as.

## Step 4 — Report

Summarize in the conversation:

- **Marked as viewed** — each file with a one-line reason
  (`tests dir`, `docs dir`, `moved`, `rename only`, `import fixes`,
  `comments only`).
- **Left for review** — the remaining files, so the user knows what their
  actual review surface is.

Do not post anything on the PR itself — no comments, no reviews. The only
write action this skill performs is marking files as viewed.

## Step 5 — Line-number analysis (always the final output)

End the response with a breakdown of the PR by changed lines, so the user
can see at a glance how much of the diff is real review work. Get per-file
line counts from the files endpoint (`additions` + `deletions` = changed
lines per file):

```bash
gh api repos/{owner}/{repo}/pulls/{number}/files --paginate \
  --jq '.[] | [.filename, .additions, .deletions] | @tsv'
```

Bucket every file into exactly one category, using the classification from
Step 2:

| Category   | What goes here                                              |
|------------|-------------------------------------------------------------|
| tests      | files under a tests directory                               |
| docs       | files under a docs directory, plus standalone `*.md` etc.   |
| moved      | renamed/moved files with no substantive change              |
| trivial    | files whose hunks are only renames, import fixes, comments  |
| logic      | everything left for review                                  |

Print a table with files and lines per category, a total row, and then one
explicit closing sentence stating the remaining review surface. Format:

```
Line analysis
| Category | Files | Lines |
|----------|------:|------:|
| tests    |     6 |   412 |
| docs     |     2 |    88 |
| moved    |     3 |   150 |
| trivial  |     3 |    27 |
| logic    |     9 |   533 |
| total    |    23 |  1210 |

Left for review: 9 of 23 files, 533 of 1210 lines (44%).
```

The "Left for review" sentence must be the last line of the response. The
`logic` row must equal the "Left for review" list from Step 4, and the sum
of the other rows must equal the files marked as viewed in Step 3.
