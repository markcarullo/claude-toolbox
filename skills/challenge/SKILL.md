---
name: challenge
description: "Pressure-test code or a plan through an adversarial loop. An Advocate defends the work, an Adversary attacks it. Outputs a recommendation or confirms it holds. Usage: /challenge [what to challenge]"
---

# challenge

Pressure-test existing work through an Advocate/Adversary loop. Everything happens in memory — no files are changed. The output is a recommendation the user approves, a confirmation that the work holds, or a list of unresolved gaps.

## Target

$ARGUMENTS

---

## How to work

Work silently through the loop. Surface each round's findings inline. When the loop ends, present the outcome and wait for the user.

---

## On entry

### Detect the target

If `$ARGUMENTS` names what to challenge, classify it: design-shaped input (approach, sequencing, architecture) → plan mode; implementation-shaped input → code mode.

Otherwise detect in order:

1. Glob for `*-PLAN.md` in cwd. If exactly one, use it → plan mode. If multiple, match against the current branch name to pick one — if no match, ask. If none, fall through.
2. Staged changes or recently edited files → code mode
3. Conversation context → infer from what's been discussed

If nothing is clear, ask: "What are we challenging?"

Read the target before starting. Hold internally: what it does, what it assumes, what's load-bearing.

---

## Roles

### Advocate

Defends the work. Studies what exists, builds the strongest possible case — what's sound, what's defensible. The Advocate must ground its defense in the actual code or plan, not in what it imagines the author intended. When the Adversary critiques, _defend before conceding_ — articulate why something is sound. If the defense holds, the Adversary must break it, not just reassert. Concede only what cannot be defended.

Round 2+: revise only what was genuinely lost. State what changed and why. If the critique points to a structural problem, propose restructuring — don't paper over it.

### Adversary

Attacks the work. Assumes it fails until the Advocate proves otherwise. Ground challenges in evidence — what the code actually does, what the tests actually cover, what the plan actually assumes. Hypothetical risks that can't be traced to the target are noise, not findings.

Each round: cross-examine the Advocate's case, surface gaps, state what's unresolved. Pass critique verbatim to the next round — never soften it.

Round 2+: go _deeper_, not wider. Scrutinize the revisions and the structure underneath — not scan for more surface nits. New surface findings after round 1 are a smell. If genuinely nothing deeper exists, state so and explain why.

**Carry the direction.** Track the thread across rounds. If a revision drifts from the trajectory of improvement — flattening a symptom instead of fixing the structure, or staying locked in the original frame when a different shape would be better — that's a finding.

---

## What each mode examines

**Plan mode:** requirements coverage, sequencing (foundational-first), gap detection, scope realism, actionability, test strategy (level per behavior with a reason).

**Code mode:** correctness, edge cases, guard clauses, error handling, side effects, readability, test coverage.

### Exhibits (code mode only)

Run what the project has configured before each round: type check, lint, tests. Exhibit failures are facts — the Advocate concedes them without argument.

Do not install tools or add config. If nothing is configured, skip and note it.

---

## The loop

Up to 3 rounds. The loop works outside-in — each round goes deeper than the last, not wider.

### Calibrate the starting altitude

The Adversary reads the target before round 1 and picks where to start:

| Signal                                  | Start at                                                    |
| --------------------------------------- | ----------------------------------------------------------- |
| Small, contained, low risk              | Correctness and edge cases — skip the frame                 |
| Medium scope, touches shared code       | Brief frame check (right place, right pattern?), then depth |
| Large, architectural, high blast radius | Full frame challenge — is this the right approach at all?   |

### Rounds

**Round 1:**

1. Run exhibits (code mode).
2. Advocate presents the case — what's sound, what's defensible.
3. Adversary challenges at the calibrated altitude. Frame-level findings take priority over detail-level ones.

**Round 2+:**

1. Advocate revises only what was genuinely lost. States what changed and why.
2. Rerun exhibits (code mode).
3. Adversary drops one altitude deeper — from frame to structure, from structure to detail. Scrutinize the revisions at this new depth.

### When the loop ends

The loop ends when any of these is true:

- **Nothing to challenge** — Adversary finds nothing load-bearing in round 1. Exit early.
- **Converged** — gaps resolved, no new ones emerge. If the Advocate revised, the revisions form the recommendation. If not, the work holds as-is.
- **Did not converge** — 3 rounds exhausted, load-bearing gaps remain unresolved.

---

## Outcome

Never write to files. Present the outcome and wait.

### Holds as-is

```
Nothing to change.

{one line on what the Adversary tested and couldn't break}
```

### Recommendation

Present what the Advocate revised and why — a recommendation, not an edit.

```
Here's what I'd change.

{summary + revised output — plan text, code block, or diff}

Apply, adjust, or discard?
```

### Did not converge

```
This needs rethinking.

{unresolved gaps, one per line}
```

---

## Guardrails

- **Never write to files during the loop.** Everything stays in memory until the user approves.
- **Never soften the Adversary.** The value is honest pressure.
- **Never inflate findings.** If the work is solid, say so. Manufacturing gaps wastes time.
- **Exhibit failures are not negotiable.** Red tests, type errors, lint errors — concede, don't argue.
- **Distinguish observed from inferred from guessed.** "I see X" / "this suggests Y" / "guessing — worth checking."
- **Adapt to conventions.** Follow codebase patterns visible in the target and CLAUDE.md if present.
