---
name: ship
description: "Ship the change. Run lint + relevant tests, verify AC if a task file is present, draft the commit, gate the writes up to push, hand off the next step. Usage: /ship"
---

# ship

Check, draft, gate the writes up to push, hand off the next step.

**Output style.** Terse, front-loaded, skimmable. Bullets and tables over prose. Full sentences only where precision demands. No preamble, no trailing recap.
✓ `Staged 4 files. Commit as "PROJ-1234: invalidate cache"?`  ✗ `I've staged 4 files for you. Would you like me to proceed with the commit?`

## At a glance

Two paths, chosen at Scope: **path 1** = commit only; **path 2** = commit + push. Path 2 splits again at handoff based on whether preflight found an existing PR.

- **Reads only** — preflight, checks, AC. Flow through; findings surface at the review gate. Preflight stops hard on a dirty tree, no changes, secrets, or a protected branch.
- **Asks once** — scope (path 1 or path 2). Default: path 1.
- **Review gate** — findings + commit message + PR description (if new PR). User revises any piece.
- **Per write** — commit, push. Each: run / manual / stop.
- **Handoff** — push command (path 1), existing PR URL (path 2 follow-up), or PR description + creation URL (path 2 new PR).
- **Never** — force-push, `--no-verify`, commits of `.env` or task/plan files, silent commits to a protected branch.

---

## Preflight

Silent unless blocked.

- `git status` + `git diff HEAD` + `git diff --cached`. Stop if: not a repo, mid-merge/rebase, unresolved conflicts, or no changes.
- Read `CLAUDE.md` if present — commit convention, PR template, base branch, branch naming.
- Base branch: `CLAUDE.md` → `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` → `main` if the ref exists, else `master`.
- Read `*-TASK.md` if there's exactly one in cwd, or one matching the branch. Don't hunt further.
- **Existing PR:** `gh pr list --head {branch} --state open --json url,number`. One result → follow-up (skip the PR-description draft; use that URL for the path 2 handoff). Zero, multiple, or any error → new PR.
- **Secret check:** if the diff includes `.env`, `.env.*`, or obvious credential patterns, stop and ask.
- **Debug leftovers:** flag any new `console.log`, `print(`, `debugger`, `TODO`, `FIXME`, or `HACK` as a finding. Doesn't block.
- **Protected branch:** if the current branch equals the base (or CLAUDE.md marks it protected), stop and ask — create a branch now / proceed anyway / abort.

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

---

## Scope

Ask which:

1. Commit only (path 1)  _(default)_
2. Commit + push (path 2)

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

Show findings first (failed checks, unmet/partial AC — empty if none), then the commit message, then the PR description if path 2 and a new PR. Ask:

1. Approve — continue to Ship
2. Revise — user names the piece (message, description, scope); re-draft and return to the gate
3. Fix findings first — re-run /ship when ready
4. Abort

---

## Ship

Gates run in order: commit, then push (path 2 only). At each gate:

1. Run it
2. Manual — print the exact command; wait for the user to confirm
3. Stop

On any write failure, surface git's error verbatim and ask: retry / manual / stop. Never `--no-verify`; never force-push.

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
