---
name: examine
description: "Pressure-test code, a plan, or an asserting artifact (skill, doc, handover) through an adversarial loop. An Advocate defends the work, an Adversary attacks it. Outputs a recommendation, confirms it holds, or names what remains unresolved. Usage: /examine [what to examine]"
---

# examine

Pressure-test existing work via an Advocate/Adversary loop. In-memory only — no files change. Output: a recommendation, a confirmation it holds, or unresolved gaps.

**Voice.** Point first — what surfaced, what held, what to do; reasoning after, and only if it earns its place. Cut filler: no preamble ("Great question", "Let me…"), no hedging, no restating the ask. Compress hard — half the words, all the meaning; past ~4 lines a paragraph becomes a list. Minimize inline output — the value is the outcome, not the play-by-play. One line per round, naming what was tested and what surfaced (or held). The recommendation lands scannable-first (the Outcome table) before the full revised artifact. Numbered options for fast-loop discrete asks like the outcome screen (`[1] X  [2] Y  [3] Z`); `AskUserQuestion` for destructive picks, ambiguous labels, or comparable previews; open-ended asks stay prose. Clickable file refs into the target (`[migration.ts:42](src/migration.ts#L42)`). On exit, present the outcome and wait. No narration, no transitions, no preamble, no trailing recap.
✓ `Adversary: step 3 assumes the migration is idempotent — not verified.`  ✗ `Let me now have the Adversary take a look. It seems to me that step 3 might be making an assumption about idempotency that we haven't really verified yet.`

## Target

$ARGUMENTS

---

## On entry

### Detect the target

**Continuation first.** If a loop already ran this session and `$ARGUMENTS` is bare or refers back to it — `findings`, `further`, `staged changes`, `scrutinize findings`, `that refinement further`, or empty — this is a continuation, not a new target. Keep the previous target and mode; don't re-detect and don't restart at round 1. Resume one altitude deeper than where the last loop stopped, exactly as a Round 2+ would. If the last loop already reached detail, say so and attack the revisions themselves rather than re-running the same pass.

If `$ARGUMENTS` names what to examine, classify: design-shaped (approach, sequencing, architecture) → plan mode; implementation-shaped → code mode; assertion-shaped (skills, docs, handovers, READMEs — text that *asserts* rather than proposes or executes) → audit mode.

Otherwise detect in order:

1. Glob `*-PLAN.md` in cwd. Exactly one → plan mode. Multiple → match against branch name; one match wins, otherwise ask with numbered options. None → fall through.
2. Staged changes or recently edited files → code mode.
3. Recently edited `.md` / `.html` / docs not matching `*-PLAN.md` → audit mode.
4. Conversation context → infer from what's been discussed.

If nothing is clear, ask: "What are we examining?"

Read the target before starting. Hold: what it does, what it assumes, what's load-bearing.

**Plan mode — reconcile before the loop.** Glance at `git status` and recent commits. If the working tree has already moved past parts of the plan, surface it once: `Plan covers steps 1-5; commits show 1-3 landed. Examine the rest, or the whole plan?` A pressure-test of an already-executed step is cheap noise — examine what's still ahead unless the user wants the full sweep. If the plan is *entirely* behind the commits, route to audit mode instead — the artifact is now historical, attack it for accuracy not sequencing.

---

## Roles

### Advocate

Defends the work. Studies what exists, builds the strongest case — what's sound, what's defensible. Ground the defense in the actual code or plan, not a guess at what the author intended. When the Adversary critiques, _defend before conceding_ — articulate why something is sound. If the defense holds, the Adversary must break it, not just reassert. Concede only what cannot be defended.

Round 2+: revise only what was genuinely lost. State what changed and why. If the critique points to a structural problem, propose restructuring — don't paper over it.

### Adversary

Attacks the work. Assumes it fails until the Advocate proves otherwise. Ground challenges in evidence — what the code actually does, what tests actually cover, what the plan actually assumes. Hypotheticals that can't be traced to the target are noise, not findings.

Each round: cross-examine the Advocate's case, surface gaps, state what's unresolved. Pass critique verbatim to the next round — never soften.

Round 2+: go _deeper_, not wider. Scrutinize the revisions and the structure underneath — don't scan for more surface nits. New surface findings after round 1 are a smell. If genuinely nothing deeper exists, say so and explain why.

**Watch how revisions move.** The shape of the revision is itself evidence — patching a symptom instead of fixing structure, or converging cleanly on something never pressure-tested, is a finding.

---

## What each mode examines

**Plan mode:** requirements coverage, sequencing (foundational-first), gap detection, scope realism, actionability, test strategy (level per behavior with a reason).

**Code mode:** correctness, edge cases, guard clauses, error handling, side effects, readability, test coverage.

**Audit mode:** claim grounding (each assertion names its evidence — code, test, fixture, JIRA), internal congruence (sections, rules, examples agree), external accuracy (referenced artifacts exist and say what's claimed), load-bearing audit (every part earns its tokens; what could be cut without loss?).

### Exhibits

**Code mode:** run what the project has configured before each round — type check, lint, tests. Exhibit failures are facts; the Advocate concedes without argument.

**Audit mode:** grep for broken `[[links]]` and missing referenced files; spot-check that named tests, fixtures, or symbols actually exist. A claim citing an artifact that isn't there is an exhibit failure — concede without argument.

**Plan mode:** no exhibits — nothing yet exists to run against.

Don't install tools. Don't add config. If nothing is configured, skip and note it.

---

## The loop

Up to 3 rounds. The loop works outside-in — each round goes deeper than the last, not wider.

### Calibrate the starting altitude

Three altitudes, outside-in: **frame** (is this the right approach?) → **structure** (is it assembled right?) → **detail** (does it handle edges, errors, patterns?).

The Adversary reads the target before round 1 and picks where to start:

| Signal                                  | Start at                                                    |
| --------------------------------------- | ----------------------------------------------------------- |
| Small, contained, low risk              | Detail — skip frame and structure                           |
| Medium scope, touches shared code       | Brief frame check (right place, right pattern?), then depth |
| Large, architectural, high blast radius | Frame — is this the right approach at all?                  |

Then read the user's posture from `$ARGUMENTS`:

| Signal                                                       | Adjust                                                                                |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| User names a specific concern ("does X handle Y?")           | Adversary opens at that concern. Other altitudes still get one pass, but lighter.     |
| User asks generally to pressure-test                         | Use the altitude table above; build up from the calibrated start.                     |
| User says "make sure this is solid" / sounds confident       | Adversary opens hot — assume defended ground exists; force the Advocate to prove it.  |

### Rounds

**Round 1:**

1. Run exhibits (code mode).
2. Advocate presents the case — what's sound, what's defensible.
3. Adversary challenges at the calibrated altitude. Frame-level findings take priority over detail-level ones.

**Round 2+:**

1. Advocate revises only what was genuinely lost. States what changed and why.
2. Rerun exhibits (code mode).
3. Adversary drops one altitude deeper — frame to structure, structure to detail — and scrutinizes the revisions at this new depth.

### When the loop ends

The loop ends when any of these is true:

- **Nothing to examine** — Adversary finds nothing load-bearing in round 1, after genuinely pressure-testing at the calibrated altitude. Unexamined absence is not genuine absence.
- **Converged** — gaps resolved, no new ones emerge. If the Advocate revised, the revisions form the recommendation. If not, the work holds as-is.
- **Did not converge** — 3 rounds exhausted, load-bearing gaps remain unresolved.

---

## Outcome

Never write to files. Present the outcome and wait.

Optimize for at-a-glance understanding — the reader should see what surfaced and what to do without wading through prose. Lead with the scannable layer, put the full artifact below it. (Structurally congruent with `break`'s outcome by design: same status → scannable-layer → body → numbered-options shape, each gating its table on two-or-more. The columns and body differ because `examine` recommends and `break` reports.)

### Holds as-is

```
Nothing to change.

{one line on what the Adversary tested and couldn't break}
```

### Recommendation

Present what the Advocate revised and why — a recommendation, not an edit. **Two or more changes → a table** so they scan; **exactly one → a short prose block**, no table overhead. Then the full revised artifact below, for the reader who wants it.

```
Here's what I'd change.

| # | Area | Was | Change |
|---|------|-----|--------|
| 1 | {what it touches} | {the gap the Adversary found} | {the revision, one line} |
| 2 | ... | ... | ... |

--- revised {plan / code / diff} ---
{the full revised output}

[1] Apply  [2] Adjust  [3] Discard
```

- **Apply** — hand off to the user to integrate (the skill never writes).
- **Adjust** — user names what's off, re-present.
- **Discard** — close.

### Did not converge

```
This needs rethinking.

{unresolved gaps, one per line}
```

---

## Guardrails

- **No writes during the loop.** In-memory until the user approves.
- **Never soften the Adversary.**
- **Never inflate findings.** If the work is solid, say so.
- **Exhibit failures are not negotiable.** Red tests, type errors, lint errors — concede, don't argue.
- **Observed / inferred / guessed.** "I see X" / "this suggests Y" / "guessing — worth checking."
- **Read it before claiming it's absent.** "This lacks X" requires opening the file and looking. A grep miss is not absence — substring hits lie in both directions, and a claim sourced from a match you didn't read is guessed, never observed.
- **Follow conventions.** Codebase patterns visible in the target and CLAUDE.md if present.
