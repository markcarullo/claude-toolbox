---
name: tdd
description: "Establish a feedback loop before writing the implementation — turn the AC into failing tests, confirm each is RED for the right reason, then hand off to /collab to drive them green. Defaults to the TASK/PLAN in cwd; also takes a behavior described in prose. Writes test files only, never the implementation. Usage: /tdd [what to test]"
---

# tdd

The loop you build before you build. In the chain between planning and building (`start → unpack → tdd → collab → break → ship`), `tdd` is the only step that authors tests before the code exists: `unpack` decides *what* to build and at *which* level, `tdd` writes those tests red, `collab` drives them green. A deliberate, separate move; a clean exit points straight at `/collab`.

The discipline is the point. A test written after the code passes because the code shaped it. A test written first fails *first* — and one that fails for the *wrong* reason (a typo, a missing import, an unwired harness) is worse than no test, because the later green looks like proof when it isn't. So every test here earns a confirmed red: it fails, and it fails because the behavior is genuinely absent, not because the scaffolding is broken.

`tdd` writes test files and nothing else — never the implementation, never makes a test pass, never ships. The handoff is the boundary: red tests in the tree, the implementation left for `collab`.

**Voice.** Terse for status (intake, the red-confirmation table, handoff). Bullets and tables for multi-item content — behaviors, AC mapping, red/green status. Numbered options for fast-loop choices (`[1] X  [2] Y  [3] Z`); `AskUserQuestion` for destructive picks, ambiguous labels, or comparable previews. Prose in active dialogue where a test-design trade-off carries nuance. Clickable file refs (`[cache.test.ts:12](src/cache.test.ts#L12)`). Distinguish observed / inferred / guessed — a test you ran and watched fail is observed; "this should fail" before running is a guess until confirmed. No preamble, no trailing recap.
✓ `3 behaviors → 3 tests. All red: 2 for the right reason, 1 errored on a missing import — fixing.`  ✗ `I've written the tests for you. They should all be failing now since we haven't written the implementation yet, which is exactly what we want in TDD.`

## Target

$ARGUMENTS

---

## On entry

### Detect the target

`tdd` defaults to the planned change in cwd. If `$ARGUMENTS` describes a behavior in prose, frame that instead.

| Target kind | Signal in `$ARGUMENTS` | What gets framed |
| --- | --- | --- |
| **TASK/PLAN** *(default)* | empty, "this", "the ticket" | The AC and the PLAN's test strategy in cwd |
| **Prose behavior** | "test that X", a described behavior | The behavior as stated, grounded against the code |

**Repo guard.** `git rev-parse --is-inside-work-tree`; on failure ask for an absolute path. Then `git status` — if the implementation already exists in the diff, say so: `tdd` is for *before* the code. Offer to proceed anyway (characterization tests over existing behavior) or to step back.

**Pair with intent.** Glob `*-TASK.md` / `*-PLAN.md` in cwd as the sibling skills do — exactly one → read it; multiple → match against the branch name; one match wins, otherwise ask with numbered options. The TASK's AC is the contract; the PLAN's Testing section, if present, already names a level and assertion per behavior — that is the spec for this skill, use it. Absent → frame from `$ARGUMENTS` and the code alone.

**Read `CLAUDE.md`** if present — test framework, test command, file-naming convention (`*.test.ts` vs `*_test.py` vs `__tests__/`), where tests live, fixtures and factories already in use. Match what exists; don't introduce a second style.

**Light scan for the harness** — find the test command (CLAUDE.md → `package.json` scripts → the project's convention), and read the nearest existing test to the code in play. Mirror its setup, imports, and assertion style. The nearest test is the template.

---

## Map behaviors

Before writing anything, decompose the contract into discrete, testable behaviors. This is the core move — the tests are only as good as this mapping.

For each behavior, fix three things:

- **What it asserts** — the observable outcome, in one line. Concrete: "returns 404 when the id is unknown," not "handles errors."
- **Level** — unit / integration / e2e. Take the PLAN's choice if it named one. Otherwise: the lowest level that can actually observe the behavior. Don't reach for an e2e when a unit test sees the same thing faster.
- **Why this level** — one line. A behavior tested at the wrong level either can't see what it claims to, or is slower and flakier than it needs to be.

**Decompose compound AC.** "Validates the input **and** logs the rejection" is two behaviors — two tests. The half that silently ships untested is usually the side effect (the log, the metric, the event), not the return value. Split before writing.

**Name the gaps the AC doesn't.** The AC states the happy path; the edge cases are where the implementation will actually break. Surface the ones worth a test — empty input, the boundary, the concurrent case, the error path — and ask which to frame now versus leave to `break` later. Don't silently write tests for behaviors no one agreed to, and don't silently skip the obvious edge.

Present the map for confirmation before writing — a short table, one row per behavior: what it asserts / level / why. The user adjusts here, where it's cheap, not after the files exist.

```
3 behaviors mapped from AC 1–2:

  #  Asserts                                  Level        Why
  1  unknown id → 404                         unit         route handler sees it directly
  2  valid id → 200 + body                     unit         same
  3  malformed body → 422, nothing persisted   integration  needs the persistence boundary

  Edge not in AC: empty id string. Frame it now, or leave to /break?
```

---

## Write the tests

One test per behavior, in the project's style, placed where the project keeps its tests.

- **Name the intent, not the mechanism.** The test name reads as the behavior: `returns 404 when the id is unknown`. A future reader learns the contract from the names alone.
- **One assertion of intent per test.** Setup can be many lines; the thing asserted is one behavior. A test that checks three things fails ambiguously.
- **No test theater.** Every assertion earns its place — a specific expected value, not `toBeTruthy()` on something that's always truthy. A test that can't fail is worse than no test.
- **Reuse the project's fixtures and factories.** Don't hand-roll a fixture that already exists. The nearest test shows what's available.
- **Reference the code that doesn't exist yet** — import the function/endpoint/module the implementation will provide. The import resolving but the behavior being absent is the *right* kind of red. The import *not* resolving is the wrong kind — see below.

For prose-behavior targets with no AC, write the test against the behavior as stated and confirm the interpretation in the test name — if the name misreads the intent, the user catches it before implementation.

---

## Confirm red — for the right reason

The skill's whole value is here. Run the tests. Every one must fail, and you must classify *why*.

Run the test command scoped to the new tests. For each, record:

- **Right-reason red** — fails on the assertion, because the behavior is genuinely absent (the function returns the wrong thing, the endpoint 404s, the value is undefined). This is the goal: the test is wired up and the gap is real.
- **Wrong-reason red** — fails on scaffolding: a missing import that *should* resolve, a typo, an unconfigured harness, a syntax error. This is a broken test masquerading as a TDD red. **Fix it and re-run** until it fails for the right reason. Don't hand off a wrong-reason red — it will turn green when the scaffolding is fixed, not when the behavior is built, and that false green is exactly what this discipline exists to prevent.
- **Unexpectedly green** — passes before any implementation. Stop. Either the behavior already exists (the test is redundant — say so, the user may cut it) or the assertion is too weak to fail (it's theater — strengthen it until it's red for the right reason).

Distinguish observed from guessed: a red you ran and read is observed. "This should fail" before running is a guess. Only report a behavior as framed once you've watched its test fail for the right reason.

```
RED CONFIRMATION

  #  Test                                      Status
  1  unknown id → 404                          ✓ red (assertion: got 200, want 404)
  2  valid id → 200 + body                     ✓ red (assertion: handler undefined)
  3  malformed body → 422                      ⚠ red (wrong reason: import unresolved) → fixing

  Re-running #3…
  3  malformed body → 422                      ✓ red (assertion: persisted anyway)

All 3 red for the right reason.
```

If a wrong-reason red can't be made right from the code alone — the harness genuinely isn't set up, a dependency is missing — say so plainly and stop. Standing up the harness is real work the user should see, not something to paper over.

---

## Handoff

Present what was framed, then point at the next step. `tdd` does not write the implementation and does not ship.

```
FRAMED

  3 tests written, all red for the right reason:
    [cache.test.ts:12](src/cache.test.ts#L12)   unknown id → 404
    [cache.test.ts:24](src/cache.test.ts#L24)   valid id → 200 + body
    [cache.int.test.ts:8](test/cache.int.test.ts#L8)  malformed body → 422

  Test command: npm test -- cache

  Next: /collab — drive them green one at a time.
        Run the command on a watch; each save tells you if you moved closer.
```

Offer next steps:

```
[1] Hand off to /collab   [2] Frame another behavior   [3] Done
```

- **Hand off to /collab** — close; the user picks up implementation against the live loop.
- **Frame another behavior** — back to the behavior map for the next AC or edge case.
- **Done** — close.

If the PLAN's Testing section listed behaviors not yet framed, name them in the handoff so the loop isn't half-built: `PLAN names 2 more behaviors (retry, timeout) — frame those too, or leave for now?`

---

## Guardrails

- **Tests only.** `tdd` writes test files and nothing else — never the implementation, never a fixture's production counterpart, never config beyond what the test needs to run. If the harness itself needs standing up, surface it as work, don't silently scaffold a framework.
- **Never make a test pass.** Going green is `collab`'s job. A test that's green at handoff is either redundant or theater — flag it, don't keep it.
- **No right-reason red, no handoff.** A wrong-reason red is a broken test. Fix it or report the blocker; never present scaffolding-failure as a TDD red.
- **Confirm the map before writing.** The behavior decomposition is where the value is — get it agreed before files exist, not after.
- **Observed / inferred / guessed.** A red you ran and read is observed. "This should fail" is a guess until confirmed. Report only confirmed reds as framed.
- **Match the project's test style.** Mirror the nearest test — framework, naming, fixtures, location. Don't introduce a second convention.
- **Don't over-frame.** Frame the behaviors the contract names plus the edges the user agrees to. Speculative tests for behaviors no one asked for are noise; the unhandled-state hunt belongs to `/break`.
- **No shipping.** Don't stage, commit, or push. The tree is left with red tests for `collab` to pick up.
