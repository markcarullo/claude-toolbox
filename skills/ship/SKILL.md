---
name: ship
description: "Ship the change. Run lint + relevant tests, verify AC if a task file is present, draft the commit, gate the writes up to push, hand off the next step. Usage: /ship"
---

# ship

Check, draft, gate the writes up to push, hand off the next step.

**Voice.** Terse, front-loaded, skimmable. Bullets and tables over prose. Numbered options for blocking asks (`[1] X  [2] Y  [3] Z`). Clickable file refs when surfacing findings (`[auth.ts:42](src/auth.ts#L42)`). Full sentences only where precision demands. No preamble, no trailing recap. Distinguish observed / inferred / guessed — AC verdicts in particular: ✓/~/✗ from a diff skim is inference, not proof. Say so when uncertain rather than ossifying a guess as a verdict.
✓ `Staged 4 files. Commit as "PROJ-1234: invalidate cache"?`  ✗ `I've staged 4 files for you. Would you like me to proceed with the commit?`

---

## Preflight

Silent unless blocked.

- `git status` + `git diff HEAD` + `git diff --cached`. Stop if: not a repo, mid-merge/rebase, unresolved conflicts, or no changes.
- Read `CLAUDE.md` if present — commit convention, PR template, base branch, branch naming.
- Base branch: `CLAUDE.md` → `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` → `main` if the ref exists, else `master`.
- Read `*-TASK.md`: exactly one in cwd → use it. Multiple → match against branch name; one match wins, otherwise ask with numbered options plus `[N] None` to skip. None → skip AC verification silently. Don't hunt further.
- **Existing PR:** `gh pr list --head {branch} --state open --json url,number`. One result → follow-up (skip the PR-description draft; use that URL for the path 2 handoff). Zero, multiple, or any error → new PR.
- **Secret check:** if the diff includes `.env`, `.env.*`, or obvious credential patterns, stop and ask `[1] Exclude and continue  [2] Commit anyway  [3] Abort`.
- **Debug leftovers:** flag any new `console.log`, `print(`, `debugger`, `TODO`, `FIXME`, or `HACK` as a finding. Doesn't block.
- **Protected branch:** if the current branch equals the base (or CLAUDE.md marks it protected), stop and ask `[1] Create a branch now  [2] Proceed anyway  [3] Abort`.

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

If most ACs come back ✗ unmet but the diff is substantive and coherent, suspect a stale TASK — the user may have moved past the original AC list. Surface as a finding: `Possible stale TASK — N ACs unmet but the diff looks like deliberate, finished work.` At the review gate, the user approves to ship anyway (Known Issues notes the divergence) or aborts to update the TASK file outside `/ship`.

---

## Scope

Ask `[1] Commit only  [2] Commit + push`. Default `[1]`.

---

## Draft

If CLAUDE.md sets a convention (commit style, PR template, non-default base), note it in one line before the draft.

**Commit message.** One line, imperative mood, under 72 chars. Reader knows what changed without opening the diff. Follow the CLAUDE.md convention if set; otherwise `{TICKET}: what changed`, or just `what changed` if there's no ticket.

**PR description** (path 2, new PR only). Written for the reviewer — short, bullets over prose, no pedantry.

- **Why** — one or two bullets on the motivation. Skip if the title already says it.
- **What Changed** — the shape of the change, not a file-by-file list. Flag anything non-obvious a reviewer would miss (behavior flips, migration order, new dependency).
- **Ticket** — link if known.

If `.github/PULL_REQUEST_TEMPLATE.md` exists, follow its structure instead. Add `Known Issues` if shipping with failures or unmet AC — on path 1, Known Issues surfaces in the Done output instead of in a description.

### Review gate

Show findings first (failed checks, unmet/partial AC — empty if none), then the commit message, then the PR description if path 2 and a new PR. Ask `[1] Approve  [2] Revise  [3] Fix findings first  [4] Abort`.

- **Approve** — continue to Ship.
- **Revise** — user names the piece (message, description, scope); re-draft and return to the gate.
- **Fix findings first** — re-run `/ship` when ready.
- **Abort** — close.

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

Commit hash, branch, base. Known Issues if shipped with failures. Note if the user overrode the protected-branch check. Then hand off the next step:

**Path 1 (commit only) — push when ready:**

```
git push -u origin {branch}
```

**Path 2, follow-up PR** (preflight found an existing PR). Print `Pushed to #{PR number}` and the existing PR URL:

```
{existing PR URL}
```

No description to copy — the PR already exists.

**Path 2, new PR.** Print the approved description in a fenced block for the user to copy, then the PR-creation URL captured from the push output:

```
https://github.com/{owner}/{repo}/pull/new/{branch}
```

Fallback if the URL wasn't captured (pre-existing tracking branch, non-GitHub remote, etc.):

```
gh pr create --base {base} --head {branch} --title "{commit message}" --web
```

---

## Guardrails

- **Approval gates every write.** Commit and push — user says yes, or it doesn't happen.
- **No hook bypass, no force-push.** `--no-verify`, `--force`, `--force-with-lease` — manual only.
- **No rewriting history.** No `--amend`, `reset --hard`, `checkout --`, `clean -fd`, `stash drop`, `branch -D`, `rebase`. Append-only; the user handles history.
- **Stage by path.** Only what the gate showed. No `git add -A` or `git add .`.
- **Abort leaves state as-is.** Don't unstage, revert, or clean up.
- **Message is the message.** No trailers or metadata beyond what the user approved.
- **Follow conventions.** CLAUDE.md, PR template, branch naming — adapt to what exists.
