---
name: ship
description: "Ship the change. Run lint + relevant tests, verify AC if a task file is present, draft the commit, gate the writes up to push, hand off the next step. Usage: /ship"
---

# ship

Check, draft, gate the writes up to push, hand off the next step.

**Voice.** Terse, skimmable. Bullets and tables over prose. Numbered options for fast-loop blocking asks (`[1] X  [2] Y  [3] Z`); `AskUserQuestion` for destructive picks, ambiguous labels, or comparable previews. Clickable file refs for findings (`[auth.ts:42](src/auth.ts#L42)`). No preamble, no trailing recap. Distinguish observed / inferred / guessed — AC verdicts especially: ✓/~/✗ from a diff skim is inference, not proof. Say so when uncertain rather than ossifying a guess as a verdict.
✓ `Staged 4 files. Commit as "PROJ-1234: invalidate cache"?`  ✗ `I've staged 4 files for you. Would you like me to proceed with the commit?`

---

## Preflight

Silent unless blocked.

- `git status` + `git diff HEAD` + `git diff --cached`. Stop if: not a repo, mid-merge/rebase, unresolved conflicts, or no changes.
- Read `CLAUDE.md` if present — commit convention, PR template, base branch, branch naming.
- Base branch: `CLAUDE.md` → `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` → `main` if the ref exists, else `master`.
- Read `*-TASK.md`: exactly one in cwd → use it. Multiple → match against branch name; one match wins, otherwise ask with numbered options plus `[N] None` to skip. None → skip AC verification silently. Don't hunt further.
- **Existing PR:** `gh pr list --head {branch} --state open --json url,number`. One result → follow-up (skip the PR-description draft; use that URL for the path 2 handoff). Zero, multiple, or any error → new PR.
- **Secret check:** if the diff includes `.env`, `.env.*`, or obvious credential patterns, stop and ask via `AskUserQuestion` dialog — the modal pause is the point. Header `Secrets`. Options: `Exclude and continue` (unstage the suspect files, proceed with the rest), `Commit anyway` (the secret will be in git history — irreversible without rewriting history), `Abort` (stop, leave the working tree as-is).
- **Debug leftovers:** flag any new `console.log`, `print(`, `debugger`, `TODO`, `FIXME`, or `HACK` as a finding. Doesn't block.
- **Protected branch:** if the current branch equals the base (or CLAUDE.md marks it protected), stop and ask via `AskUserQuestion` dialog — the modal pause is the point. Header `Branch`. Options: `Create a branch now` (move pending changes to a new feature branch, then proceed), `Proceed anyway` (commit directly to the protected branch — visible to the whole team, may trigger CI/deploy), `Abort` (stop, leave the working tree as-is).

---

## Checks

Quick and trivial. Lint the diff's files. Run tests scoped to the diff. Skip if not configured, if scoping isn't obvious, or if the command looks slow — the pre-commit hook is authoritative. Don't install tools. Don't run the full suite.

```
LINT   ▸ {✓ / ✗ N / — skipped}
TESTS  ▸ {✓ / ✗ N / — skipped}
```

Failures surface as findings at the review gate; they don't block.

---

## AC verification

_Skip if no task file was read in preflight._ One-line verdict per AC from a diff skim: **✓ met** / **~ partial** / **✗ unmet**. Unmet and partial ACs surface as findings.

**Decompose compound ACs before verdicting.** "Add X **on the template** and **in the mapping**" is two contracts — confirm the diff touches each artifact. The artifact half (binary, seed, config) silently ships missing while the code half is obvious. Code refs to the artifact's name ≠ the artifact updated; for static assets, open the file.

If most ACs come back ✗ unmet but the diff is substantive and coherent, suspect a stale TASK — the user may have moved past the original AC list. Surface as a finding: `Possible stale TASK — N ACs unmet but the diff looks like deliberate, finished work.` At the review gate, the user approves to ship anyway (Known Issues notes the divergence) or aborts to update the TASK file outside `/ship`.

---

## Scope

Ask `[1] Commit only  [2] Commit + push`. Default `[1]`.

---

## Draft

If CLAUDE.md sets a convention (commit style, PR template, non-default base), note it in one line before the draft.

**What makes the writeup good** — holds for the commit message and the PR description alike. One principle: **carry what the source can't, claim nothing it doesn't show.** Its corollaries:

- **Claim only what's shown.** The test for any line: can you point to the changed lines that prove it? The diff shows every change but not the code around it — claim the effect those lines have, not how code you can't see behaves. Hold the why/Summary strictest, since the reader trusts it as framing.
- **Lead with the why.** The source shows the mechanics; the writeup carries what it can't — the problem, the reason it was needed. Omit it rather than invent one.
- **Keep the non-obvious.** A subtle mechanism, a deliberate non-change, a gotcha — put it where the thing it concerns lives, never dropped for tidiness.
- **Size to the reader, not the source.** Every line earns its place; if the source already says it, you don't. A self-evident change is subject-only.

**Commit message.** One line, imperative mood, under 72 chars. Reader knows what changed without opening the diff. Follow the CLAUDE.md convention if set; otherwise `{TICKET}: what changed`, or just `what changed` if there's no ticket.

**PR description** (path 2, new PR only). Written for the reviewer — short, bullets over prose, no pedantry.

- **Why** — one or two bullets on the motivation. Skip if the title already says it.
- **What Changed** — the shape of the change, not a file-by-file list. A new entity through the standard stack is "wired end-to-end," not a bullet per layer; spend words on the non-routine — a guard, a default, a behavior flip, a migration order, a new dependency a reviewer would miss.
- **Ticket** — link if known.

If `.github/PULL_REQUEST_TEMPLATE.md` exists, follow its structure instead. Add `Known Issues` if shipping with failures or unmet AC — on path 1, Known Issues surfaces in the Done output instead of in a description.

### Review gate

Ask via `AskUserQuestion` dialog with a preview — the commit message (and PR description on path 2) is what's being approved, and the preview lets the user see it side-by-side with the choice. Header `Ship`. Options:

- `Approve` — continue to Ship. Preview: findings first (failed checks, unmet/partial AC — omit if none), then the commit message, then the PR description if path 2 and a new PR.
- `Revise` — user names the piece (message, description, scope); re-draft and return to the gate.
- `Fix findings first` — re-run `/ship` when ready.
- `Abort` — close.

---

## Ship

Gates run in order: commit, then push (path 2 only). At each gate, ask `[1] Run  [2] Manual  [3] Stop`:

- **Run** — execute the command.
- **Manual** — print the exact command; wait for the user to confirm.
- **Stop** — abort. State leaves as-is.

On any write failure, surface git's error verbatim and ask `[1] Retry  [2] Manual  [3] Stop`. Never `--no-verify`; never force-push.

### 1. Commit

Stage tracked changes, excluding `*-TASK.md`, `*-PLAN.md`, `.env`, `.env.*` (but keep `.env.example` / `.env.sample`), and anything the user excluded at the review gate. Show the staged list alongside the approved message, then ask.

- Run → `git commit -m "{message}"`
- Manual → print the command

### 2. Push  _(path 2)_

- Run → `git push -u origin {branch}`. Capture the `https://github.com/{owner}/{repo}/pull/new/{branch}` URL GitHub prints in the push output for the Done handoff.
- Manual → print the command

### Done

Commit hash, branch, base. Known Issues if shipped with failures. Note if the user overrode the protected-branch check. Then hand off the next step in a fenced block:

- **Path 1** (commit only) — `git push -u origin {branch}`.
- **Path 2, follow-up PR** — print `Pushed to #{N}` and the existing PR URL. No description to copy.
- **Path 2, new PR** — print the approved description in a fenced block, then the PR-creation URL captured from push output (`https://github.com/{owner}/{repo}/pull/new/{branch}`). Fallback if not captured: `gh pr create --base {base} --head {branch} --title "{commit message}" --web`.

---

## Guardrails

- **Approval gates every write.** Commit and push — user says yes, or it doesn't happen.
- **No hook bypass, no force-push.** `--no-verify`, `--force`, `--force-with-lease` — manual only.
- **No rewriting history.** No `--amend`, `reset --hard`, `checkout --`, `clean -fd`, `stash drop`, `branch -D`, `rebase`. Append-only; the user handles history.
- **Stage by path.** Only what the gate showed. No `git add -A` or `git add .`.
- **Abort leaves state as-is.** Don't unstage, revert, or clean up.
- **Message is the message.** No trailers or metadata beyond what the user approved.
- **Follow conventions.** CLAUDE.md, PR template, branch naming — adapt to what exists.
