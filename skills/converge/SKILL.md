---
name: converge
description: "Autonomous descent on the implementation. Runs measure → change → re-measure against tests, typecheck, and lint until fitness is maxed and the gates hold, and stops with a named reason when it stalls. Usage: /converge [target] [gate on /x, /y] [note]"
---

# converge

You own the round; every other skill owns a step (`tdd → converge → minimal`). Orient from the task, plan, and log, then descend: measure what's red, make one change, re-measure. Descent lowers what's red; fitness counts what's green — one slope, read from either end. Stop when fitness is maxed and the gates hold, or the moment progress stalls — say so rather than settling in a local minimum, a shape where each further fix adds a branch instead of a green. One run is one descent in one basin — the shape the plan's fork chose. The search across basins is the outer loop: the user and `/unpack`, with the log as memory. The user is not watching; every stop names its reason.

Distinguish observed / inferred / guessed — a green test is observed, "this is probably the right shape" is inferred.

**Voice.** Point first; reasoning only where the decision turns on it. No preamble, no hedging, no restating the ask. Past ~4 lines a paragraph becomes a list. Here the point is the status, result, or stop reason. Bullets for lists of 2+; tables when items share attributes. A question the loop can't resolve is an exit, asked once as numbered options (`[1] X  [2] Y  [3] Z`) so `/steady N` answers it and the log keeps the pick; never `AskUserQuestion` — a modal can't be answered by `/steady`. Clickable file refs (`[dashboard.ts:42](src/dashboard.ts#L42)`). No narration between rounds; the report speaks at the stop.
✓ `Stalled after round 6: 4/6 green for two rounds, fix attempts add branches to cache.ts. Fork #invalidate-vs-version — rival was versioned keys.`  ✗ `I've been working on this for a while and I think we might be stuck. Let me explain what I tried and why it didn't quite work out.`

**Log.** With a task file in play, keep the decision trail in `{TICKET}-LOG.md` beside it — one line per entry, appended from the shell (`printf '%s\n' "- $(date +%FT%R) {line}" >> {TICKET}-LOG.md`), never via `Write`/`Edit`, never from a subagent. No task file, no log. `enter [converge]` with the target and the gate list; one `round [converge] 3 · 4/6 green · 2 files` line per round; `fork#slug chose X over Y — criterion` at a shape-level choice — alternatives that differ in files touched or structure, not in naming; `retract →#slug reason` when a stall abandons a heading — an approach taken, named by its fork slug, not a markdown heading; `outcome` at the stop, with the reason.

## Target

$ARGUMENTS

---

## On entry

Glob `*-TASK.md` in cwd. Exactly one → use it. Multiple → match against branch name; one match wins, otherwise ask with numbered options. None → no task, plan, or log; the target comes from `$ARGUMENTS` or the red tests.

Read silently, in order: `{TICKET}-TASK.md` → `{TICKET}-PLAN.md` → `{TICKET}-LOG.md` → repo-root `CLAUDE.md` if present → conversation context + `git status` + recent commits on the branch. Hold: the target, the approach and its rival, the files the plan names, and the log's forks and retractions — a retracted heading is not re-proposed, a settled fork is not re-opened. CLAUDE.md shapes the patterns to conform to and may name gates to run.

If the log ends with an `outcome [converge]` line followed by a `steer [steady]` line, the last stop's question has been answered: enter from that state, and round 1 is the steered move — don't re-ask.

Reconcile silently: does the work-in-progress (commits, staged/unstaged diff) still match what TASK/PLAN describe? If the plan says "step 1: scaffold" and the scaffold is already in place, hold that as drift — don't descend from a stale map. On meaningful divergence, take the Not pre-authorized exit before round 1: `Plan says X; tree shows Y. [1] Descend from the tree  [2] Descend from the plan  [3] Stop` — then wait. A stale plan misleads the next session; the user fixes it, not the loop.

**`$ARGUMENTS`** carries up to four things, each known by its phrase:

| Phrase | Effect |
|---|---|
| a behavior, or a scope within the plan | the target |
| `gate on /x, /y` | adds those skills to gate 2, in that order, after any CLAUDE.md names |
| `try the rival if stalled` | one autonomous retry after a stall, then stop |
| anything else ("descend further") | a steer for the run; the target stays the AC |

**The target** is fixed for the run; the candidate moves. In order of precedence:

- `$ARGUMENTS` names it.
- Otherwise the task file's AC, bounded by the plan's steps.
- Neither → ask, one line.

A target that could be read two ways is not a target. Ask before round 1, not after round 4.

---

## Fitness

Deterministic and ordered — the project's tests, then type check, then lint; the PLAN's Testing section names which tests if present. Maximize it: a red that turns green is progress, a green that stays green is not, a green that turns red is a **regression** — revert that change before anything else, never patch forward over it.

Fitness discriminates correctness, not shape. Two green candidates tie; the gates and the stall rules rank them.

If nothing is configured, say so and stop — a loop with no fitness function is a random walk. If fitness is already maxed on entry and the target is unmet, there is no gradient — stop: `Nothing red to descend on — /tdd first.`

---

## The round

Measure → one change → re-measure. One change is one hypothesis: a test made green, a type error cleared, a regression reverted. Don't batch three fixes into a round; when a round fails, the batch hides which one failed.

After each round, one log line: `round [converge] {n} · {green}/{total} green · {files touched}`.

Between rounds, hold the thread: an earlier decision in the log or the plan is not contradicted without a `retract`; a problem already solved is not solved again.

### Stall

Stop the descent, before the gates, when any of these is counted — not felt:

- **Fitness flat** — two rounds with no gain.
- **Scope growing without the target asking** — a round touches a file the plan doesn't name, or adds an abstraction no AC needs. Overengineering is the stall most often caught by the user, so catch it first.
- **Shape drift** — each fix adds a branch or a special case, or the same file is reworked a third time.
- **Investigation drift** — three fix attempts without a stated hypothesis.
- **Gate cycle** — the gates have sent the loop back twice on the same shape.

A stall is a finding, not a failure. Log `retract →#slug` against the fork that chose the current shape, and stop with the rival named.

---

## Gates

Run once fitness is maxed, cheap to expensive, each inline via `Skill` in this context — never a subagent, so a gate's own `enter`/`outcome` log lines are legitimate. Converge is the caller: a gate's options are consumed, never offered; its "present and wait" addresses converge, and converge does not wait. A gate that sends the loop back re-runs after the fix until it holds; the gate-cycle stall caps that at two.

| Gate | Holds | Sends back | Stalls |
|---|---|---|---|
| 1 `/examine`, passed `the uncommitted diff` — a bare call would continue an earlier loop | nothing to change | a non-structural recommendation — each item is one round | a structural recommendation (the shape, not a case within it), or did not converge |
| 2 lenses — any review skill `CLAUDE.md` says to run before declaring done, wherever it says it, then any `gate on` names | nothing found | findings by the lens's own tiers: top tiers one round each; no tiers, every finding one round | a finding that is a shape, not an edge |
| 3 `/break`, passed `the uncommitted diff` | nothing broke | `break`'s remedy pass names the test for each confirmed breakage — write it **red**, then the descent resumes on fitness | never |

A lens's lowest tier and a breakage that can't be expressed as a test are loose ends: reported, not fixed. Gates hold when each has run on the final shape with nothing left to fix. A gate finding that costs a new round counts toward the gate-cycle stall.

`/minimal` is not a gate — it is the next step in the hand-off.

---

## Exits

Every exit stops and reports; none continues silently.

| Exit | When | Report says |
|---|---|---|
| **Converged** | fitness maxed, gates hold | what landed, rounds, gates run |
| **Stall** | any stall rule counted | which rule, the fork retracted, the rival from its `fork` line — reshape in `/unpack` |
| **Wrong target** | a fix would contradict another AC, or the app contradicts the ticket | the contradiction, verbatim from both sides, then `[1] Ticket wins  [2] App wins  [3] Stop` |
| **Not pre-authorized** | a decision beyond the plan, or blast radius beyond it | the decision as numbered options, wait |

Never re-orient alone: a retracted shape's rival is named for the user, not tried. If `$ARGUMENTS` pre-authorizes it ("try the rival if stalled"), one retry, then stop.

---

## Report

At every stop:

```
{Converged / Stalled: rule / Wrong target / Not pre-authorized}

Done: {bullets, each with a file ref}
Loose ends: {anything flagged but not addressed, or "None"}
Fitness: {green}/{total} · typecheck ✓ · lint ✓   Rounds: {n}   Gates: {examine ✓ · lenses ✓ · break ✓, or which stopped it}

Next: /minimal, then /ship — or /unpack to reshape (rival: {from the fork line})
{or, for a question exit: the question, then [1] X  [2] Y  [3] Stop}
```

A stopped run resumes on `/steady {note}` in the same session — a bare number picks the option, free text steers the next round; either lands in the log as a `steer` line.

---

## Guardrails

- **No shipping.** Don't stage, commit, or push.
- **Regressions revert.** A green that goes red is undone first, not patched over — by editing the change back out, never by `checkout --` or `stash`.
- **Blast radius:** before any edit, check scope and ripple against the files the plan names — or, with no plan, the files the red tests import, plus the task's leads when there is a task file — and, either way, the test files beside the red tests, since a gate-3 breakage lands there. Outside them is a stall, not a judgment call.
- **Nothing destructive.** No `rm` of untracked or unread files, no `checkout --`, `clean -fd`, `stash drop`, `reset --hard`, `branch -D`. Ask; the user runs them.
- **Read before overwrite.** Never replace a file you haven't read. "It's probably generated" isn't having read it.
- **Reuse before authoring.** Exhaust what exists — helpers, utilities, fixtures — before writing a new one. A near-miss sibling you extend beats a fresh implementation next to it.
- **Conform to the codebase.** Patterns visible in sibling implementations and `CLAUDE.md` win over a cleaner shape the codebase doesn't use.
