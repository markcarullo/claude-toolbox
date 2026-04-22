---
name: start
description: "Turn a JIRA ticket into an oriented brief, scope it against the codebase, fill gaps with the user, then set up a workspace with a task file. Usage: /start PROJ-1234"
---

# start

Orient the user, then set up the workspace. The brief is the artifact — aim well enough that downstream skills have a solid start.

Collaborate on ambiguity rather than guessing. Stay grounded in what's given — ticket text and a light scan — not speculation. Don't skip steps or proceed past a blocking failure without user input.

**Output style.** Terse and front-loaded for status chatter (intake, self-review, summary screen, launch). TASK.md content stays prose — it's a durable artifact the user re-reads. No preamble, no trailing recap.
✓ `PROJ-1234 fetched (Bug, 3 ACs). Leads: src/cache.ts, src/dashboard.ts.`  ✗ `I've successfully fetched the ticket PROJ-1234. It has 3 acceptance criteria and I found 2 leads. We're ready to proceed.`

## Ticket

$ARGUMENTS

---

## How to work

Ask plainly when blocked — no special prompt formatting. Numbered options for choices. One question at a time.

---

## Intake

### Repo guard

Run `git rev-parse --is-inside-work-tree`. On failure, ask for an absolute path to a repo. Then `git status` — fail on mid-merge, mid-rebase, or unresolved conflicts before any ticket work begins.

### Fetch the ticket

If no ticket ID, ask. Use the Atlassian MCP. If the MCP requires a cloudId, fetch first via `getAccessibleAtlassianResources`.

**Core fields first:** title, type, description, AC, plus repro/expected/actual for bugs. Fetch links, parent epic, attachments, and comments only on demand — when the ticket body references them or self-review flags a gap they'd close. Otherwise note "not fetched."

On fetch failure, ask for a corrected ticket ID or pasted content.

### Read CLAUDE.md _(parallel with ticket fetch)_

Read repo-root `CLAUDE.md` if present. Extract branch naming, test commands, framework hints, conventions. Proceed without if absent.

### Light code scan _(parallel with ticket fetch)_

Orient only — no deep file reading.

- Skim directory / package layout.
- Note test framework and nearby spec patterns.
- Surface if the code points somewhere the ticket doesn't.

### Validate workability _(needs ticket body)_

Stop at the first gap that would block a developer. The bar:

- **Framing coherent** — names the actual problem, not a symptom or a pre-baked solution.
- **Description** present.
- **AC** concrete and verifiable (sharpen vague ones).
- **Repro steps** realistic (bugs only).
- **Dependencies** named.
- **Scope coherent** — no two equally valid interpretations.

Collaborate to resolve before continuing.

### Code leads _(needs ticket body)_

Grep ticket keywords — component names, error strings, feature flags, AC nouns.

Produce **2-3 best leads** — each a candidate with a one-line "why," not an assertion.

### Branch name

Derive from CLAUDE.md convention. Slug: lowercase, hyphenated, no articles or conjunctions, no punctuation, max 40 chars. Always derive, never ask — unless no convention exists, then ask once.

---

## Self-review

Silent. Walk the brief against: AC coverage, AC verifiability, repro steps (bugs), blocking ambiguities, scope coherence, framing coherence, starting point plausibility. On gaps: one round only, max 2 questions (most load-bearing). Anything still unresolved goes in Open Questions.

If the user already has a read — a hypothesis, a scope instinct — weave it in rather than overwrite. Name where you diverge. Don't solicit a hypothesis they haven't offered.

---

## Summary screen

```
TICKET     {TICKET}: {title}
TYPE       {Bug / Feature / Chore}
BRANCH     {branch}

SUMMARY    {2-5 sentences. What's being solved,
            why it matters, what to know first.}

LEADS      {N}

{If gaps remain from self-review:}
GAPS       {one per line — what's unresolved and why it matters}

[1] GO    [2] REVIEW BRIEF    [3] REJECT
```

- `[1] GO` — proceed to launch.
- `[2] REVIEW BRIEF` — render task file draft inline. Flag the part where the user's judgment matters most (usually LEADS — a hypothesis, not a verdict), then: `[1] GO  [2] REVISE  [3] CANCEL`. `REVISE` → ask what's off, re-render. `CANCEL` → back to summary.
- `[3] REJECT` — ask targeted questions, revise, re-render.

---

## Task file

Written as `{TICKET}-TASK.md` in the working directory (e.g. `PROJ-1234-TASK.md`).

Scale to the ticket's complexity — simple tickets get core sections only; complex tickets add parent epic, longer summary, and the Helpful Context block.

```markdown
# TASK: {TICKET} — {title}

## Summary

{2-3 sentences for simple tickets, 2-5 for complex ones. What's being solved, why it matters, what to know first.}

## Ticket Details

- **Type:** {Bug / Feature / Chore}
- **Ticket:** {TICKET} — {URL}
- **Branch:** {branch}
- **Parent epic:** {title + status, or "None"} _(complex tickets only)_

## Acceptance Criteria

{Each AC, concrete and verifiable.}

## Reproduction _(bugs only — omit otherwise)_

**Steps:** {verbatim, or refined via collaboration}
**Expected:** {what should happen, and why}
**Actual:** {what happens instead, and the impact}

## Starting Points

{2-3 best leads with one-line "why" — hypothesis, not verdict.}

- `path/to/file` — {why this is a candidate}
- **Test:** `{command}` · **Nearest specs:** `{paths}`

## Helpful Context _(complex tickets only)_

- **Test command:** {from package.json or CLAUDE.md}
- **Test framework + specs nearest the starting points:** {...}
- **Framework hints:** {from CLAUDE.md, e.g. "React — components in src/components/"}
- **Feature flags / env vars mentioned:** {..., or "None"}
- **Linked tickets:** {TICKET — title — status — link type}
- **Attachments:** {filename — URL} (not fetched; open if relevant)

## Open Questions

{Or "None."}
```

---

## Launch sequence

### Preflight

Check for `code` CLI (`which code`). Warn if missing but continue.

### Worktree or branch?

Ask: `[1] BRANCH (branch in current repo)  [2] WORKTREE (isolated folder + branch)`

### Create

Check for an existing branch or worktree first. Reuse if found — omit `-b` when attaching a worktree to an existing branch.

**Worktree:** `git worktree add "../worktrees/{TICKET}" -b "{branch}"`
**Branch only:** `git checkout -b "{branch}"`

### Write task file

**Worktree:** `../worktrees/{TICKET}/{TICKET}-TASK.md` | **Branch only:** `./{TICKET}-TASK.md`

If the file already exists, ask: overwrite / keep the existing one / abort.

### Open VS Code and print exit

Open the workspace: `code {worktree path, or repo root}`. Skip if `code` was missing in preflight. Don't run `claude` via shell — it requires an interactive TTY.

```
READY

  Branch   {branch}
  Worktree ../worktrees/{TICKET}    (if applicable)
  {TICKET}-TASK.md  written
  VS Code  {opening / skipped — open manually: {path}}

  Solo? Open the TASK file, start at Starting Points.

  AI-assisted? Open Claude Code and try:

    /unpack — to plan your approach before writing code
    /collab — to pair on the implementation
```
