---
name: break
description: "Pre-ship adversarial gate — try to break the change you just built, before you ship it. An Attacker proposes breakages; a Skeptic tries to refute each one's reachability. Only findings with a traceable path to the bad state survive. Defaults to the uncommitted diff against its TASK/PLAN; also takes an area, a PR, or a workflow. Report-only — ranked findings plus a doc, never files a ticket. Usage: /break [what to attack]"
---

# break

The last adversarial look before you ship — the stop between `collab` and `ship` (`collab → break → ship`): try to break what you just wrote while it's still cheap to fix. A separate, deliberate step; `ship` doesn't run it for you, and `break` never ships. The bar is high: a breakage counts only if you can trace how the system reaches the state that triggers it. "What if this were null" is not a finding; "this is null whenever an add is interrupted mid-flow, and here's the path" is.

The class of bug to hunt — *worked example from one codebase; the mechanism generalizes*: a real fix (a duplicate-name check) that wasn't null-safe against a state the system itself produces (an entity created in step one of a two-phase add, not yet named in step two). No user did anything wrong — the code just didn't account for its own reachable states. The engine below is domain-neutral; the example is illustrative.

Not to be confused with `examine` code mode: the posture is opposite. `examine` *defends* — an Advocate argues the work is sound and concedes only what the Adversary breaks. `break` has nothing to defend — it assumes something is reachable-broken and hunts. Reach for `break` when the risk is an unhandled state the happy path never visits.

In-memory only — `break` never writes (beyond one optional report doc), never edits the target, never ships, never files. It finds; you fix or file (Outcome covers disposition). A clean pass ends by pointing at `/ship`.

**Voice.** Minimize the play-by-play — the value is the surviving findings, not the sparring. One line per round naming what was attacked and whether it survived refutation. Findings land scannable-first (the Outcome table), never a stack of prose stanzas. Numbered options for fast-loop discrete asks (`[1] X  [2] Y  [3] Z`); `AskUserQuestion` for ambiguous target picks or comparable previews; open-ended asks stay prose. Clickable file refs into the target (`[PrimeBrokersPanel.tsx:71](src/view/routes/admin/organisation/OrganisationDialog/PrimeBrokersPanel.tsx#L71)`). Distinguish observed / inferred / guessed — a code path you read is observed, a state you believe is reachable is inferred until traced. No preamble, no trailing recap.
✓ `Attacker: normalize(name) over the list — name is null for a created-not-named entity. Skeptic: is that state reachable? Yes — an interrupted two-phase add leaves it (producer at workflowEpic.ts:231). Survives.`  ✗ `Let me have the Attacker take a look here. It seems like there might be a potential null issue worth exploring around the name handling.`

## Target

$ARGUMENTS

---

## On entry

### Detect the target

`break` defaults to the change you just built. If `$ARGUMENTS` names a different target, classify it; otherwise the uncommitted diff is the target.

| Target kind | Signal in `$ARGUMENTS` | Entry point |
| --- | --- | --- |
| **Local diff** *(default)* | empty, "this", "what I just built" | `git diff HEAD` (+ staged) — the change about to ship, read against its TASK/PLAN |
| **Area** — a file, component, module | A path, a component name, "attack the X panel" | Read the named code and its immediate collaborators |
| **PR / commit** — review someone else's, or a past change | A PR URL/number, a commit hash | `gh pr diff` / `git show` — attack the blast radius of that change |
| **Workflow** — a user journey end-to-end | "the add-prime-broker flow", "the rerate journey" | Trace every state transition in the journey; probe each for unhandled states |

Detection order when `$ARGUMENTS` is empty or ambiguous:

1. A PR/commit reference in `$ARGUMENTS` → PR/commit mode.
2. A named path/component → area mode.
3. Conversation context names a journey → workflow mode.
4. Otherwise → **local diff mode** (the pre-ship default). If `git diff HEAD` is empty, there's nothing to break — say so and point at whatever the user might have meant.

**Repo guard.** `git rev-parse --is-inside-work-tree`; on failure ask for an absolute path. Read `CLAUDE.md` if present — conventions tell you what states the codebase considers valid, which sharpens reachability judgments.

**Pair the diff with its intent** _(the pre-ship move)_. Glob `*-TASK.md` / `*-PLAN.md` in cwd as `start`, `collab`, `unpack`, and `ship` do — exactly one → read it; multiple → match against the branch name. In local-diff mode this is the core of the gate: the TASK/PLAN is what the change was *supposed* to do, the diff is what it *actually* does, and the breakages live in the gap — the states the AC implies but the diff doesn't handle, the new code path the author had a clean mental model of while the system can put it in a dirtier one. Read the intent, then hunt the states it forgot. Absent → proceed against the diff alone; `break` does not require a workspace.

Read the target before the loop. Hold: what it does, what states it can be in, what it assumes about its inputs, what produces those inputs.

### Map the state space (the core move)

Before attacking, enumerate the states the target can actually occupy — not the happy-path states the author had in mind, but every state the *system* can put it in. This is where the worked example lived: the author assumed the entity always has a name; the system produces nameless ones during a two-phase add.

For the target, list:

- **Inputs and their producers** — for each value the code consumes, what writes it? Can the producer emit null, empty, partial, stale, duplicate, out-of-order, or not-yet-populated values?
- **Multi-phase operations** — anything created in one step and completed in another leaves an intermediate state. Interrupted/abandoned/re-entered flows linger there.
- **Lifecycle gaps** — reconnect, refresh, retry, cancel, error-recovery. What state is the entity in when these fire mid-operation?
- **Re-entrancy / re-render** — validation or computation that re-runs on every render/event iterates whatever is currently present, including transient bad states.

This map is the Attacker's ammunition. State it briefly before round 1.

---

## Roles

### Attacker

Hunts for breakages. Assumes the code fails somewhere and goes looking. Grounds every candidate in the actual code and the state map — names the exact line, the exact value, the exact bad state. Proposes a breakage as a claim with three parts:

> **Break:** what fails (the exception, wrong result, corrupted state, blocked action).
> **Trigger:** the specific state that causes it.
> **Path:** how the system reaches that state — the producer, the flow, the lifecycle event. *This is the part the Skeptic attacks.*

A breakage with no path is a hypothesis, not a finding. The Attacker must propose the path; if they can't, they say so and the candidate is held as speculative, not reported as real.

Round 2+: go deeper into surviving findings and the state map, not wider for fresh surface nits. New shallow "what if null" candidates after round 1 are a smell.

### Skeptic

Tries to refute reachability. Assumes every candidate is unreachable until the Attacker proves the path. The Skeptic's job is not to agree — it's to *break the path*:

- Is there a guard upstream that prevents the bad state? (Read it — don't assume.)
- Does the producer actually emit the claimed value, or is that a guess?
- Is the triggering state pruned, validated, or normalized before it reaches the code?
- Does the flow that supposedly produces the state actually run, or is it dead/unreachable?

A candidate **survives** only if the Skeptic looks for a refutation and fails to find one. If the Skeptic finds a guard that makes the state unreachable, the candidate is **killed** — name the guard and move on. If reachability can't be settled from the code (needs runtime state), the candidate is **unverified** — reported separately, never as confirmed.

Pass refutations verbatim. Never soften to keep a finding alive.

---

## Exhibits

Ground the hunt in facts the project already exposes — don't install or configure anything.

- **Type checker / compiler** — a type error in the target is a free finding (or confirms a null-unsafe path). Run what's configured.
- **Existing tests** — run the tests covering the target. Note what they assert and, crucially, what states they *never* construct. The state the tests never set up is often the one that breaks.
- **Grep for the producer** — when the Attacker claims a value comes from somewhere, grep it and read the producer. Reachability claims must cite producers, not assume them.

Exhibit facts are not negotiable. If the type checker flags the exact path the Attacker proposed, the Skeptic concedes reachability.

---

## The loop

Up to 3 rounds, deeper each round, never wider.

### Calibrate the starting depth

| Target signal | Start at |
| --- | --- |
| Small, contained (one function, a tight diff) | Detail — null/empty/partial inputs, single bad state |
| Medium, touches shared state or producers | State map first — what intermediate states exist — then detail |
| Large workflow or high-blast-radius change | Frame — which transitions in the journey have no handler at all |

Then read the user's posture:

| Signal | Adjust |
| --- | --- |
| User names a specific fear ("does X handle a cancelled add?") | Attacker opens there; other states still get one pass, lighter |
| User asks generally to "try to break it" | Build from the calibrated start up |
| User sounds confident it's solid | Attacker opens hot — assume a reachable bad state exists and hunt for it |

### Rounds

**Round 1:**

1. Run exhibits (type check, target tests, producer greps).
2. Attacker proposes breakages from the state map — each as Break / Trigger / Path.
3. Skeptic attempts to refute each path. Survivors, kills, and unverified are recorded.

**Round 2+:**

1. Attacker deepens — chase the survivors' implications and the next layer of the state map.
2. Rerun exhibits if the target moved.
3. Skeptic refutes the new candidates at the deeper level.

### When the loop ends

- **Nothing breaks** — after a genuine state-map hunt at the calibrated depth, the Skeptic refutes every candidate. Unexamined absence is not absence — say what you actually attacked.
- **Findings stand** — one or more breakages survived refutation with a traced path. The loop ends when no new survivors emerge.
- **Exhausted** — 3 rounds done, some candidates remain unverified (reachability needs runtime). Report them as such.

---

## Outcome

Never write to Jira, GitHub, or the target's files. Present the report and wait.

### Ranked findings

Lead with what surfaced, so the reader sees every breakage, its severity, and what to do without reading prose. **Two or more confirmed findings → a table**; **exactly one → the same columns as a short block**, no table overhead. Order by severity, then confidence. Unverified and killed candidates are one-liners below.

```
{N} breakages survived refutation, {N} killed, {N} unverified.

── Confirmed ──

| # | Sev | What breaks | Where | Fix |
|---|-----|-------------|-------|-----|
| 1 | {SEV} | {one-line failure} | [file:line](path#Lline) | {concrete one-liner — "null-guard trimToLower" / "filter nameless before .some"} |
| 2 | ... | ... | ... | ... |

  1 — reachable via: {trigger → path: producer / flow / lifecycle event}. Skeptic tried {refutation}, failed because {reason}.
  2 — ...

── Unverified (reachability needs runtime) ──
- {candidate} — blocked on {what's needed to confirm: a log value, a repro, a runtime state}

── Killed ──
- {candidate} — refuted by {the guard / producer behavior that makes it unreachable}
```

The indented path line carries break's whole bar — a finding is real only because reachability was traced — so it stays, one line per finding. Drop it only when the "What breaks" cell already makes reachability self-evident.

Severity: **Critical** (data loss/corruption, security, the operation is impossible), **Major** (a core workflow breaks under a reachable condition), **Minor** (degraded, a workaround exists), **Cosmetic** (display only). If the project (CLAUDE.md, a sibling skill) defines its own severity scale — domain-specific bands the team already uses — use that instead.

Then offer next steps, branched on the result.

**Clean pass — nothing survived** (the goal of a pre-ship gate):

```
Nothing broke. {one line on what was attacked and couldn't be reached}

Ready to /ship.
```

**Findings survived:**

```
[1] Write the report doc  [2] Fix a finding  [3] Done
```

- **Write the report doc** — produce the Markdown file (below). This is the only file `break` writes.
- **Fix a finding** — for a breakage in your own diff (the pre-ship case), hand it to the user to fix in `collab` or directly; `break` does not edit the target. After fixing, re-run `break` to confirm it's closed, then `/ship`. For a finding in code *outside* your change (an area or PR you attacked), this is instead a file step: the doc is the ticket body — paste it by hand or feed it to a project's issue-analyst skill if one exists. Either way `break` does not fix and does not file — a surviving-but-unaddressed finding is better than a speculative ticket or a blind patch.
- **Done** — close, no file.

### The report doc

Only on request (option 1). File name: `break-<target-slug>.md` in cwd — slug from the most stable ID the target has: the ticket key (`break-BQ-13539.md`), the PR number (`break-pr-4821.md`), the file/component name (`break-PrimeBrokersPanel.md`), or a short kebab of the journey (`break-add-prime-broker.md`).

```markdown
# Break Report: <target>

**Date:** <today>
**Target:** <local diff / area / PR or commit / workflow — with the specific path, PR, or branch>
**Attacked:** <one line on what state space was explored>
**Result:** <N confirmed, N unverified, N killed>

---

## Confirmed Breakages

### [<Severity>] <what breaks>

- **Where:** `<path:line>`
- **Break:** <the failure>
- **Trigger:** <the bad state>
- **Path to the state:** <producer, flow, lifecycle event — the traced reachability>
- **Refutation attempted:** <what the Skeptic tried; why it failed to refute>
- **Fix direction:** <concrete>

```<language>
<the load-bearing code snippet>
```
*File: `<path>`, lines <N>–<M>*

<repeat per confirmed finding>

---

## Unverified Candidates

| Candidate | Why unverified | What would confirm it |
|---|---|---|
| <candidate> | reachability needs runtime state | <log value / repro / runtime check> |

---

## Killed Candidates

| Candidate | Refuted by |
|---|---|
| <candidate> | <the guard or producer behavior that makes it unreachable> |

---

## State Map

<the states the target can occupy, and which producer/flow puts it there — the reasoning that drove the hunt>

---

*Generated by /break on <date>. Report-only — no edits, no commits, no tickets. Pre-ship: fix the diff and re-run; otherwise file the finding.*
```

---

## Guardrails

- **No writes anywhere but the report doc.** No Jira, no GitHub, no edits to the target. The doc is written only on explicit request.
- **No finding without a traced path.** Reachability is the bar. A breakage that needs an impossible state is not a finding — it's killed. Untraced reachability is *unverified*, never *confirmed*.
- **Never soften the Skeptic.** Its job is to kill findings; surviving the kill is what makes a finding real.
- **Never inflate.** If the Skeptic refutes everything, say so plainly. A clean target is a valid outcome — don't manufacture breakages to look productive.
- **Observed / inferred / guessed.** A path you read in the code is observed. A producer behavior you believe but didn't read is inferred. A hunch is guessed — and guessed reachability lands a candidate in *unverified*, not *confirmed*.
- **Read the guard before claiming it's missing.** "This is null-unsafe" requires confirming no upstream guard exists — grep and read it. A guard you didn't look for is not an absent guard.
- **Find, don't fix or ship.** `break` reports; it never edits the target and never commits. The user fixes or files (Outcome covers which) — keep the blind-patch and speculative-ticket risks both on the far side of the handoff.
- **Follow conventions.** Codebase patterns and CLAUDE.md define which states are considered valid — judge reachability against them, not against generic paranoia.
```
