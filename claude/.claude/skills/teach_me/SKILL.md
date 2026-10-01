---
name: teach_me
description: Deep-dive study plan generator. Breaks a subject into a structured checklist of topics, finds relevant materials (docs, papers, videos, tutorials), and produces a study plan markdown file. Use when the user wants to learn or understand a topic in depth.
argument-hint: <subject to learn>
allowed-tools: Bash, Read, Write, Glob, Grep, Agent, AskUserQuestion, WebSearch, WebFetch
---

# Teach Me

Generate a comprehensive, structured study plan for a given subject. The goal is to help the user build deep understanding by breaking the subject into digestible topics, ordering them logically, and linking high-quality learning materials.

## Arguments

Parse `$ARGUMENTS` as the **subject** the user wants to learn. It can be broad ("distributed systems") or narrow ("flash attention algorithm").

## Process

### Step 1: Scope the subject

Ask the user clarifying questions to understand:
- **Current level**: What do they already know? (beginner / intermediate / advanced)
- **Goal**: Why are they learning this? (job interview, project, curiosity, paper reading)
- **Depth**: How deep do they want to go? (overview / working knowledge / expert-level)
- **Time budget** (optional): How much time do they want to spend?

Keep it to 2-3 focused questions max. If the subject and context are already clear from conversation history, skip straight to planning.

### Step 2: Build the topic tree

Break the subject into a hierarchical checklist of topics:

1. **Prerequisites** - foundational concepts needed before diving in
2. **Core concepts** - the essential building blocks, ordered from fundamental to advanced
3. **Applied topics** - practical applications, implementation details, hands-on exercises
4. **Deep dives** (optional) - advanced subtopics for expert-level understanding

Each topic should be:
- Specific enough to study in one sitting (30-90 min)
- Ordered so each topic builds on the previous ones
- Tagged with estimated study time

### Step 3: Find materials

For each topic, search the web and find 2-4 high-quality resources. Prefer:
- **Official documentation** and authoritative references
- **Seminal papers** for academic/research topics
- **Well-known tutorials** (blog posts, video courses) from recognized authors
- **Interactive resources** (exercises, playgrounds, notebooks) where available
- **GitHub repos** with educational examples or implementations

For each resource, include:
- Title and URL
- Type (doc / paper / video / tutorial / exercise / repo)
- Why it's useful for this specific topic

### Step 4: Generate the study plan markdown

Write the study plan to a markdown file at: `~/study_plans/study_plan_<subject_slug>.md`

Where `<subject_slug>` is a lowercase, hyphenated version of the subject (e.g., `flash-attention`, `distributed-systems`).

Create the `~/study_plans/` directory if it doesn't exist.

Use this format:

```markdown
# Study Plan: <Subject>

**Level**: <beginner/intermediate/advanced>
**Goal**: <user's stated goal>
**Estimated total time**: <sum of all topic times>
**Created**: <date>

---

## Prerequisites

- [ ] **<Topic name>** (~<time>)
  <1-line description of what to learn>
  - [<Resource title>](<url>) — <type> — <why useful>
  - [<Resource title>](<url>) — <type> — <why useful>

## Core Concepts

- [ ] **<Topic name>** (~<time>)
  <1-line description>
  - [<Resource title>](<url>) — <type> — <why useful>
  - [<Resource title>](<url>) — <type> — <why useful>

- [ ] **<Topic name>** (~<time>)
  <1-line description>
  - [<Resource title>](<url>) — <type> — <why useful>

## Applied Topics

- [ ] **<Topic name>** (~<time>)
  <1-line description>
  - [<Resource title>](<url>) — <type> — <why useful>

## Deep Dives (Optional)

- [ ] **<Topic name>** (~<time>)
  <1-line description>
  - [<Resource title>](<url>) — <type> — <why useful>

---

## Notes

_Use this space for your own notes as you study._
```

### Step 5: Confirm with the user

After generating the plan:
1. Show a summary of the topic tree (just the checklist, no resources) so the user can review the structure
2. Tell them the file path
3. Ask if they want to adjust anything (add/remove/reorder topics) **before starting**

## Rules

- **DO NOT edit the study plan markdown once created** unless the user explicitly asks you to. The user checks off items manually as they study. Unsolicited edits could lose their progress.
- If the user asks you to help them study a topic from the plan, teach them interactively in conversation — do NOT modify the markdown.
- Only update the markdown when the user says something like "mark X as done", "update the plan", "add topic Y", or "edit the study plan".
- When updating, preserve all existing checkmarks and notes.

## Task

$ARGUMENTS
