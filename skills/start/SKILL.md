---
name: start
description: "Fetch a JIRA ticket, scope it against the codebase, fill gaps with the user, then set up a workspace with a task file. Usage: /start PROJ-1234"
---

# start

Turn a JIRA ticket into a brief sharp enough to act on, and set up the workspace.

Collaborate on ambiguity rather than guessing. Do not skip steps or proceed past a blocking failure without user input.

## Ticket

$ARGUMENTS

---

## How to work

Ask questions plainly when blocked — no special prompt formatting. For choices, use numbered options. One question at a time.

---

## Intake

### Repo guard

Run `git rev-parse --is-inside-work-tree`. If it fails, ask for an absolute path to a repo. Then check `git status` — fail on mid-merge/mid-rebase/unresolved conflicts before any ticket work begins.

### Fetch the ticket

If no ticket ID is provided, ask. Use the Atlassian MCP. Obtain cloudId first if needed.

**Lazy-fetch.** Core first (title, type, description, AC, repro/expected/actual for bugs). Links, parent epic, attachments, comments on demand only — when the ticket body references them or the self-review flags a gap they'd close. Otherwise note "not fetched."

While the MCP call is in flight, run the CLAUDE.md read and code scan in parallel.

On fetch failure, ask for a corrected ticket ID or pasted content.

### Read CLAUDE.md _(parallel with ticket fetch)_

Read repo-root `CLAUDE.md` if present. Extract branch naming, test commands, framework hints, conventions. Proceed without it if absent.

### Light code scan _(parallel with ticket fetch)_

Orient, do not analyze. No deep file reading.

- Skim directory / package layout
- Note test framework and nearby spec patterns

### Validate workability _(needs ticket body)_

Stop at the first gap that would block a developer. The bar: description present, AC concrete and verifiable (sharpen vague ones), repro steps realistic for bugs, dependencies named, scope coherent (no two equally valid interpretations). Collaborate to resolve before continuing.

### Code leads _(needs ticket body)_

Grep ticket keywords — component names, error strings, feature flags, AC nouns.

Produce **2-3 best leads** — each a candidate with a one-line "why," not an assertion.

### Branch name

Derive from CLAUDE.md convention. Slug: lowercase, hyphenated, no articles/conjunctions/punctuation, max 40 chars. Always derive, never ask (unless no convention exists — then ask once).

---

## Self-review

Silent. Walk the brief against: AC coverage, AC verifiability, repro steps (bugs), blocking ambiguities, scope coherence, starting point plausibility. On gaps: ask one round only, max 2 questions (most load-bearing). Anything still unresolved goes in Open Questions.

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

- `[1] GO` — proceed to launch
- `[2] REVIEW BRIEF` — render task file draft inline, then: `[1] GO  [2] REVISE  [3] CANCEL`
- `[3] REJECT` — ask targeted questions, revise, re-render

---

## Task file

Written as `{TICKET}-TASK.md` in the working directory (e.g. `PROJ-1234-TASK.md`).

Scale to the ticket's complexity — lighter tickets get core sections only, heavier tickets add parent epic, longer summary, and the Helpful Context block. The difference is ceremony, not quality.

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

Check for `code` CLI (`which code`) — warn if missing but continue.

### Worktree or branch?

Ask: `[1] WORKTREE (isolated folder + branch)  [2] BRANCH (branch in current repo)`

### Create

Check for existing branch/worktree first. Reuse if found.

**Worktree:** `git worktree add "../worktrees/{TICKET}" -b "{branch}"`
**Branch only:** `git checkout -b "{branch}"`

### Write task file

**Worktree:** `../worktrees/{TICKET}/{TICKET}-TASK.md` | **Branch only:** `./{TICKET}-TASK.md`

### Open VS Code and print exit

Do not run `claude` via shell (requires interactive TTY).

```
READY

  Branch   {branch}
  Worktree ../worktrees/{TICKET}    (if applicable)
  {TICKET}-TASK.md  written
  VS Code  opening

  Solo? Open the TASK file and start with the
  Starting Points.

  AI-assisted? Open Claude Code and try:

    /think — to plan your approach before writing code
    /collab — to pair on the implementation
```
