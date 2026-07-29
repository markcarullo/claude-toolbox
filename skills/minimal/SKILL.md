---
name: minimal
description: "Reduce an artifact to what's load-bearing for its consumer — nothing surplus, nothing missing. Works on any artifact: code comments, tests, docs, skills and prompts, committed prose. Defaults to the uncommitted diff; also takes a file, an area, or text. Cuts are report-only and gated; rewrites preview as a diff. Usage: /minimal [what to reduce]"
---

# minimal

Every line earns its place. Nothing to add, nothing to take away.

Run it after the code works, before `break` and `ship`: strip what doesn't carry weight, tighten what does, and make what's left read like a person wrote it. Governs **artifacts** — code, comments, tests, docs, committed prose. Not your replies to the user (`/tldr` owns those), not how you move through a task (`/steady` owns that).

Minimal is not minimalist. The floor is as real as the ceiling: a comment carrying the *why* is load-bearing no matter how short the file gets. Removing it is a silent, permanent loss — nobody reviews a deleted comment the way they review deleted code. So the cut is evidence-bound and gated; the rewrite is not.

**Voice.** Point first — the cut, the rewrite, the verdict; reasoning after, and only if it earns its place. Cut filler: no preamble ("Great question", "Let me…"), no hedging, no restating the ask. Compress hard — half the words, all the meaning; past ~4 lines a paragraph becomes a list. Minimize the play-by-play — the value is the reduced artifact, not the reasoning that got there. Findings land scannable-first (the Outcome table), never a stack of prose stanzas. Numbered options for fast-loop discrete asks (`[1] X  [2] Y  [3] Z`); `AskUserQuestion` for destructive picks or comparable previews; open-ended asks stay prose. Clickable file refs into the target (`[cache.ts:42](src/cache.ts#L42)`). Distinguish observed / inferred / guessed — redundancy you traced to specific code is observed, redundancy you sense is inferred, redundancy you assume from the shape of the artifact is guessed. No preamble, no trailing recap.
✓ `L42 "increment the counter" — restates counter++ on L43. Cut.`  ✗ `I noticed that the comment on line 42 seems like it might be a bit redundant with what the code below it is already doing.`

## Target

$ARGUMENTS

---

## On entry

### Detect the target

`minimal` defaults to the change you just built. If `$ARGUMENTS` clearly names a target, classify it with the table below; anything else falls to the detection order.

| Target kind | Signal in `$ARGUMENTS` | Entry point |
| --- | --- | --- |
| **Local diff** *(default)* | empty, "this", "the staged changes" | `git diff HEAD` — tracked changes, staged and unstaged |
| **Area** — a file, component, module | A path, a component name | Read the named file(s) whole |
| **Prose** — a doc, a description, a message | A `.md` path, "the PR description", pasted text | The text as given |

Detection order when `$ARGUMENTS` is empty, ambiguous, or names something the table doesn't cover:

1. A named path → area mode (prose mode if it's a doc).
2. Conversation context names an artifact just written → that artifact.
3. Otherwise → **local diff mode**. `git diff HEAD` covers tracked changes; a file you just created is untracked and invisible to it, so check `git status --porcelain` for `??` entries too and read those whole. Both empty → say so and point at whatever the user might have meant.

**Scope guard.** In diff mode, only touch lines the diff added or changed. Pre-existing code around the change is out of scope — reducing it inflates the diff a reviewer has to read. Say so once if the surrounding code is where the real noise lives. In area and prose mode the named file is the boundary — read a sibling to confirm a pointer, never to reduce it.

**Pair the diff with its intent.** Glob `*-TASK.md` / `*-PLAN.md` in cwd as the sibling skills do — exactly one → read it; multiple → match against the branch name, one match wins, otherwise ask with numbered options. The AC tells you which comments are load-bearing: a note explaining a deliberate edge case the ticket asked for is not noise, however redundant it looks against the line below it. Absent → proceed against the diff alone.

Read `CLAUDE.md` if present — comment conventions, doc requirements, and required headers are not noise. A codebase that mandates JSDoc on exports has made that call already.

### Name the consumer

Before reducing anything, state who receives this artifact — in one line. It decides everything downstream.

| Artifact | Consumer | Standard |
| --- | --- | --- |
| Inline comment | The next person editing this line | Why, not what. The code says what |
| Test name / assertion | Someone reading a failure at 3am | Names the behavior and the expectation |
| PR description | A reviewer who hasn't seen the code | Why + a map. Not an inventory |
| Doc / README | Someone who doesn't have the context yet | Prerequisites before the thing that needs them |
| Commit message | Someone scanning `git log` in a year | What changed, in one line |

These are examples, not the set. For an artifact not listed, derive the same three: **who receives it**, **what they can't get elsewhere**, and **whether a person reads the words**. That last one gates stage 4 — an agent-read artifact (a skill, a prompt, a machine-consumed doc) skips it.

If the consumer is genuinely unclear, ask — don't guess. "Minimal for whom" is the whole question, and the wrong answer cuts the wrong things.

---

## The four stages

Run in order. The order is load-bearing: never spend effort compressing a line you should delete, and never polish the voice of prose you're about to compress.

### 1. Focus — what is this for?

Read the target. Hold: what it does, who consumes it, what each part is carrying. Nothing is cut or changed in this stage.

### 2. Prune — cut what doesn't earn its place

**The bar (this is the whole skill).** Something can be marked for cutting only if you can **point at what already carries it** — the code that says it, the section that states it, the sibling that owns it. Name it. Can't point → it stays. Untraced redundancy is *unverified*, never *confirmed* — the same standard `break` holds for reachability.

**What earns its place** is whatever the consumer can't get elsewhere:

- **The why** — rationale, trade-offs, the reason it's this way. If this is the only record, cutting it destroys it.
- **The non-obvious** — a gotcha, a deliberate non-change, an ordering constraint, a workaround for something elsewhere.
- **The pointer** — a link to a ticket, a spec, a sibling, a related file.
- **Whatever a convention mandates.** See `CLAUDE.md`.

**What doesn't** is anything already carried. It wears different names per artifact — in a comment it's *restatement* or *scaffolding*; in a skill it's a *vestigial instruction*, a *rephrasing*, or content a *sibling already owns*; in prose it's an *inventory* of what the reader can see. Same test throughout: point at what carries it, or leave it. Pointing outside the target — at a sibling, a producer, a caller — is the one case that sends you out of it: read it to confirm, and if you can't, the cut is unverified rather than proposed.

Two cases the pointing test handles differently:

- **Stale content** — describes behavior that no longer exists. Verify against the current artifact before calling it stale.
- **Excess in aggregate** — individually defensible parts that together exceed what the consumer needs. Judged whole, not per line. Say so, and propose the shape rather than a list of cuts.

### 3. Distill — concentrate what survives

Same meaning, fewer words. Applies to what stage 2 kept.

- Cut qualifiers that carry nothing: `just`, `really`, `actually`, `simply`, `basically`.
- Cut throat-clearing: `It's worth noting that`, `Note that`, `Keep in mind`.
- One idea, one line. Split a comment doing two jobs; merge two doing one.
- Prefer the short synonym when it's as precise. Never when it's less precise.

**Never compress substance.** Identifiers, paths, commands, error strings, config values, ticket keys — byte-for-byte exact. Compression is of *how* it's said, never *what* is said.

### 4. Lean — make it read like a person  *(only where a person reads the words)*

- **No AI-tells.** Em-dashes as connectors in code comments, `Note:` openers, `This function is responsible for`, symmetrical triads, hedge-stacking.
- **No pedantry.** Don't explain the language to someone writing it. `// increment i` over `i++` is the canonical failure.
- **Plain words.** Name things the way the code and the domain name them.
- **Match the surroundings.** A file with terse lowercase comments doesn't want full-sentence prose dropped in. The local style is a convention.

---

## Calibration

Scale the pass to the artifact. A two-line diff doesn't get a four-stage sweep.

Stage 1 always runs — it's reading, not changing. Past that, two questions set the depth:

- **How much is there to cut?** Fresh or generated content is where restatement concentrates — run stage 2 hard. A small diff with few comments may have nothing to cut; say so and go straight to 3.
- **Does a person read this artifact?** No — a skill, a prompt, a generated file — → stop after stage 3. Stage 4 is for human readers only.

One rule beyond that: **the bar for cutting rises on content you didn't write.** You have less context on why it's there, and the pointing test is the only thing standing in for that context.

Then read the user's posture from `$ARGUMENTS`:

| Signal | Adjust |
| --- | --- |
| User says "be aggressive" / "this is bloated" | Full stages. The bar for cutting stays — aggression buys thoroughness, never a lower standard |
| User names one concern ("just the comments") | That stage only. Mention what you skipped |

---

## Outcome

Two products, separated by blast radius. Present both, then wait.

**Cuts** are proposals — never applied without a go-ahead. Two or more → a table; exactly one → a short prose block; none → say so in a line and go straight to the rewrites.

**Rewrites** (stages 3–4) are lossless and preview as a diff, applied on approval like any edit.

```
{n} cuts proposed · {m} lines tightened

| # | Where | What | Redundant with |
|---|-------|------|----------------|
| 1 | [cache.ts:42](src/cache.ts#L42) | `// increment the counter` | `counter++` on L43 |
| 2 | ... | ... | ... |

Kept — load-bearing:
- [cache.ts:88](src/cache.ts#L88) — why the TTL is 300, not the default. Only record of it.

Unverified — needs your call:
- [auth.ts:12](src/auth.ts#L12) — looks stale, but the producer is outside the diff.

--- rewrites (preview) ---
{the diff for stages 3-4}

[1] Apply all  [2] Rewrites only  [3] Pick cuts  [4] Discard
```

- **Apply all** — cuts and rewrites.
- **Rewrites only** — the safe half. Cuts stay proposed.
- **Pick cuts** — user names which by number.
- **Discard** — close, nothing written.

On close, point at the next step: `/break` to attack what's left, or `/ship` if the change is already gated. `minimal` never ships.

If nothing needs reducing, say so plainly:

```
Nothing to reduce.

{one line on what was checked and why it holds}
```

---

## Guardrails

- **Never cut without pointing.** "This is redundant" requires naming the code that already says it. A guess is *unverified*, never a proposal.
- **Cuts are gated, always.** Stages 3–4 may apply on approval like any edit; stage 2 never applies without an explicit go-ahead. Silence is not consent.
- **The why is sacred.** Rationale, trade-offs, gotchas — if the comment is the only record, it stays. When in doubt, keep and say why.
- **Substance is byte-exact.** Code, commands, paths, identifiers, error messages, config values. Brevity applies to prose, never to substance.
- **Stay inside the diff.** In diff mode, don't reduce pre-existing code — it inflates the review surface. Surface it as a note instead.
- **Never delete a test to make a suite smaller.** Redundant coverage needs both tests named and the overlap shown; a test that's merely slow or awkward is not redundant.
- **Conventions outrank minimalism.** Required headers, licence blocks, mandated docstrings, generated-file markers — leave them.
- **Reduce, don't rewrite.** Restructuring code, renaming, or changing behavior is out of scope — that's `/collab`. If the real problem is the code and not its noise, say so and stop.
- **Prose follows `ship`'s writeup principle.** Carry what the source can't, claim nothing it doesn't show. `ship` holds the canonical statement — apply it, don't restate it.
