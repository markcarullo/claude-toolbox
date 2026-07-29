---
name: ship
description: "Ship the change. Run lint + relevant tests, verify AC if a task file is present, draft the commit, gate the writes up to push, hand off the next step. Usage: /ship"
---

# ship

Check, draft, gate the writes up to push, hand off the next step.

**Voice.** Point first — the answer, the verdict, the result; reasoning after, and only if it earns its place. Cut filler: no preamble ("Great question", "Let me…"), no hedging, no restating the ask. Compress hard — half the words, all the meaning; past ~4 lines a paragraph becomes a list. Bullets and tables over prose. Numbered options for fast-loop blocking asks (`[1] X  [2] Y  [3] Z`); `AskUserQuestion` for destructive picks, ambiguous labels, or comparable previews. Clickable file refs for findings (`[auth.ts:42](src/auth.ts#L42)`). No preamble, no trailing recap. Distinguish observed / inferred / guessed — AC verdicts especially: ✓/~/✗ from a diff skim is inference, not proof. Say so when uncertain rather than ossifying a guess as a verdict.
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

**What makes the writeup good** — holds for the commit message and the PR description alike. One principle: **carry what the source can't, claim nothing it doesn't show.** The diff shows the mechanics; the writeup carries what it can't. Two constraints on every line: **claim only what's shown** — the diff shows every change but not the code around it, so claim the effect those changed lines have, not how code you can't see behaves; hold the why strictest, since the reader trusts it as framing. And **size to the reader** — every line earns its place; if the diff already says it, you don't.

Build it from these three, in order of value:

- **The why.** The problem, the reason it was needed — the writeup is the only place it gets recorded, so lead with it. If the change and the ticket give you none, omit it rather than invent one.
- **A map of the core files.** Name the principal files or areas, each with a short note on what changed there — not an inventory: skip what the diff makes clear (a rename, a lockfile bump) and don't restate edits it shows. Across many files, one bullet per shared move, named by flow or module: a new entity through the standard stack is "wired end-to-end", not a bullet per layer. Spend the words on what isn't routine — a guard or permission check, a default value, a case handled differently from the rest.
- **The non-obvious.** A subtle mechanism, a deliberate non-change, a gotcha — put it where the thing it concerns lives, never dropped for tidiness.

If it's all obvious from the diff, the writeup is short.

**Commit message.** One line, imperative mood, under 72 chars. Reader knows what changed without opening the diff. Follow the CLAUDE.md convention if set; otherwise `{TICKET}: what changed`, or just `what changed` if there's no ticket.

**PR description** (path 2, new PR only). Written for the reviewer — short, bullets over prose, no pedantry. The three ingredients above become sections: **Why**, **What Changed** (the map), and a **Ticket** link if known.

If `.github/PULL_REQUEST_TEMPLATE.md` exists, follow its structure instead. Add `Known Issues` if shipping with failures or unmet AC — on path 1, Known Issues surfaces in the Done output instead of in a description.

**Fence for copy-clean.** Both surfaces get drafted inside a ``` code fence so the user copies them without markdown leaking in. Headings are `**bold**`, never `#` — in the previewed draft `#` renders as a heading instead of a bold label, and it reads wrong in a commit body. No tables, no trailers.

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
