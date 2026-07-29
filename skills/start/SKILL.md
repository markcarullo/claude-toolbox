---
name: start
description: "Turn a JIRA ticket into an oriented brief, scope it against the codebase, fill gaps with the user, then set up a workspace with a task file. Usage: /start PROJ-1234"
---

# start

Orient the user, then set up the workspace. The brief is the artifact — aim well enough that downstream skills have a solid start.

Collaborate on ambiguity rather than guessing. Stay grounded in what's given — ticket text and a light scan — not speculation. Don't skip steps or proceed past a blocking failure without user input.

**Voice.** Point first — the finding, the gap, the status up front; reasoning after, and only if it earns its place. Cut filler: no preamble ("Great question", "Let me…"), no hedging, no restating the ask. Compress hard — half the words, all the meaning; past ~4 lines a paragraph becomes a list. Terse for status chatter (intake, self-review, summary, launch). Bullets and tables for multi-item content (leads, gaps, AC). Numbered options for fast-loop choices (`[1] X  [2] Y  [3] Z`); `AskUserQuestion` for destructive picks, ambiguous labels, or comparable previews. Clickable file refs in chat (`[cache.ts:42](src/cache.ts#L42)`); TASK.md keeps plain backtick paths. No preamble, no trailing recap. Distinguish observed / inferred / guessed — leads especially: a grep hit is observed, "this is probably where it lives" is inferred. Flag unverified hunches so the brief doesn't ossify them as fact.
✓ `PROJ-1234 fetched (Bug, 3 ACs). Leads: src/cache.ts, src/dashboard.ts.`  ✗ `I've successfully fetched the ticket PROJ-1234. It has 3 acceptance criteria and I found 2 leads. We're ready to proceed.`

## Ticket

$ARGUMENTS

---

## Intake

Ask plainly when blocked — no special formatting, one question at a time.

- **Repo guard.** `git rev-parse --is-inside-work-tree`; on failure ask for an absolute path. Then `git status` — fail on mid-merge, mid-rebase, or unresolved conflicts before any ticket work.
- **Fetch the ticket.** If no ticket ID, ask. Use the Atlassian MCP; if it needs a cloudId, fetch via `getAccessibleAtlassianResources`. Core fields first: title, type, description, AC, plus repro/expected/actual for bugs. Fetch links, parent epic, attachments, comments only on demand. On failure, ask for a corrected ID or pasted content.
- **Read CLAUDE.md** _(parallel with fetch)_. Extract branch naming, test commands, framework hints, conventions. Proceed without if absent.
- **Light code scan** _(parallel with fetch)_. Orient only — skim layout, note test framework and nearby specs. Surface if the code points somewhere the ticket doesn't.
- **Validate workability** _(needs ticket body)_. Stop at the first gap that would block a developer:
  - **Framing coherent** — names the actual problem, not a symptom or pre-baked solution.
  - **Description** present.
  - **AC** concrete and verifiable (sharpen vague ones).
  - **Repro steps** realistic (bugs only).
  - **Dependencies** named.
  - **Scope coherent** — no two equally valid interpretations.
- **Split compound ACs.** "Add X **on the template** and **in the mapping**" is two deliverables — the artifact half is the one that silently ships missing. For bug tickets citing a parent AC, confirm both halves landed before scoping.
- **Open binary assets.** xlsx, png, pdf — parse the file, don't trust JIRA's description of it. Asset state drifts; ticket text doesn't.
- **Code leads** _(needs ticket body)_. Grep ticket keywords — component names, error strings, feature flags, AC nouns. Produce **2-3 best leads**, each a candidate with a one-line "why," not an assertion.
- **Branch name.** Derive from CLAUDE.md convention. Slug: lowercase, hyphenated, no articles or conjunctions, max 40 chars. Always derive, never ask — unless no convention exists, then ask once.

---

## Self-review

Silent. Walk the brief against:

- AC coverage
- AC verifiability
- Repro steps (bugs)
- Blocking ambiguities
- Scope coherence
- Framing coherence
- Starting point plausibility

On gaps: one round only, max 2 questions (most load-bearing). Anything still unresolved goes in Open Questions.

If the user already has a read — a hypothesis, a scope instinct — weave it in rather than overwrite. Name where you diverge. Don't solicit a hypothesis they haven't offered.

### Calibrate brief depth

Read the user's familiarity from `$ARGUMENTS` and the ticket framing, then shape the summary:

| Signal                                                          | Adjust                                                                                  |
| --------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `$ARGUMENTS` names files, modules, or a concrete hypothesis     | Tight summary. Skip orientation. Leads acknowledge the user's read first, add what's missing. |
| New area, broad ticket, no hypothesis offered                   | Fuller summary. Helpful Context expanded. Leads as candidates with one-line "why."      |

---

## Summary screen

Short fixed-width block: `TICKET / TYPE / BRANCH / SUMMARY / LEADS` (counts only — details live in the task file draft below). If self-review left gaps, add a `GAPS` line — one per line, what's unresolved and why it matters.

Ask via `AskUserQuestion` dialog with a preview — the brief is what's being approved, and the preview lets the user see it side-by-side with the choice instead of taking a separate review step. Header `Launch`. Options:

- `GO` — proceed to launch. Preview: the full task file draft rendered as it will be written, with the part where the user's judgment matters most (usually LEADS — a hypothesis, not a verdict) flagged inline.
- `REVISE` — user names what's off; re-render and re-ask.
- `REJECT` — ask targeted questions, revise, re-render.

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

## Leads

{2-3 best leads with one-line "why" — hypothesis, not verdict.}

- `path/to/file` — {why this is a candidate}

## How to Test

- **Test command:** `{from package.json or CLAUDE.md}`
- **Nearest specs:** `{paths to existing tests near the leads}`

## Helpful Context _(complex tickets only)_

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

Ask via `AskUserQuestion` dialog — the choice shapes where the workspace lives, and the option labels need descriptions to disambiguate. Header `Workspace`. Options: `Branch` (new branch in the current repo — fast, shares the working tree, switching contexts means stashing or committing), `Worktree` (isolated folder under `../worktrees/{TICKET}` with its own working tree — switching contexts is `cd`, no stashing, but takes more disk).

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

  Solo? Open the TASK file, start at Leads.

  AI-assisted? Open Claude Code and try:

    /unpack — to plan your approach before writing code
    /collab — to pair on the implementation
```
