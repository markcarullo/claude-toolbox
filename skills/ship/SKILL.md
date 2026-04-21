---
name: ship
description: "Ship the change. Run checks, verify AC, draft commit and PR, then stage, commit, push, and open the PR — with user approval at each gate. Usage: /ship"
---

# ship

Run checks, verify AC, draft the commit and PR, ship it. You do the legwork; the user approves at each gate. Be fast — ask only when blocked.

## Instructions

$ARGUMENTS

---

## How to work

Work silently between gates. Surface results inline. When the user must decide, ask plainly — numbered options for pure choices, open question when they need to type.

If the diff hasn't been through `/examine` and isn't trivial (config tweak, rename, one-line fix), mention it once before drafting — never block.

---

## Preflight

All steps silent unless something blocks. Run in parallel where possible.

### Git state

Run `git status` and `git diff --stat`. Stop if: not a git repo, mid-merge/rebase, unresolved conflicts, or no changes to commit.

### Read the briefing

Glob for `*-TASK.md` in cwd. If exactly one, use it. If multiple, match against the current branch name to pick one — if no match, ask. If none, derive ticket ID from the branch name — if unclear, ask.

Read in order (do not guess at contents):

1. `{TICKET}-TASK.md` — extract ticket ID, title, type, AC list, branch name.
2. `{TICKET}-PLAN.md` — note approach and open questions.
3. Neither present — proceed. The diff and branch name are the only context.

### Read the diff

```bash
git diff HEAD
git diff --cached
```

Hold internally: files changed, nature of each change, rough scope.

### Read CLAUDE.md

If present, extract: commit message convention, PR template, branch naming, base branch, ship-time conventions. Proceed without if absent.

### Detect base branch

Check: `CLAUDE.md` convention → `git remote show origin` HEAD → fall back to `main`/`master`.

---

## Checks

Only run what the project already has configured. Do not install tools or add config.

Run in parallel where possible: (1) type check, (2) lint, (3) tests.

Report inline:

```
TYPES  ▸ {✓ pass / ✗ N errors / — not configured}
LINT   ▸ {✓ pass / ✗ N errors / — not configured}
TESTS  ▸ {✓ pass / ✗ N failures / — not configured}
```

If any check fails, ask: fix, ship anyway, or abort?

- **Fix** — auto-fix lint; surface type/test errors for the user. Re-run after. Loop until clean or the user chooses otherwise.
- **Ship anyway** — proceed; PR description will note known issues.
- **Abort** — stop.

---

## AC verification

_Skip if no task file was found._

Map each AC from the task file to diff evidence: **✓ met** (diff satisfies it), **~ partial** (incomplete/ambiguous), **✗ unmet** (no evidence).

```
AC VERIFICATION

✓  {AC 1} → {file:change that satisfies it}
~  {AC 2} → {what's partial and what's missing}
✗  {AC 3} → not addressed in diff
```

If any AC is unmet or partial, ask: ship as-is, review gaps, or abort? Unmet AC noted in PR if shipping.

---

## Cleanup scan

Scan the diff for things that shouldn't ship:

- No console.log / print / debugger statements
- No commented-out code blocks
- No TODO/FIXME/HACK added without ticket reference
- No .env, credentials, or secrets in staged files

If anything is found, surface and ask — one item at a time.

---

## Draft

### Commit message

One line. Prefix with the resolved ticket ID, imperative mood, under 72 chars. The reader should know what changed without opening the diff. No body unless the diff is genuinely ambiguous. Follow CLAUDE.md convention if one was found.

Format: `{TICKET}: what changed`

### PR title

Same as the commit message. If the commit message works as a title, reuse it.

### PR description

The reader should understand the change without opening JIRA or scrolling — absorb enough ticket context that the JIRA link is a reference, not a dependency. Bullets and tables over prose. No padding.

**Scale to the diff.** Small changes (1-3 files, focused) get a lean description. Larger changes get the full structure. Use what fits, drop what doesn't:

```markdown
## Why

{The problem or motivation — one or two bullets. Pulled from the task file, ticket, or the diff itself.}

## What Changed

{Bullets for a focused change. Table grouped by concern for larger diffs. Not a file-by-file list.}

## Relevant Tests

{Before/after — what was failing, what passes now. Run the relevant tests and include the output. The user may supplement with screenshots.}

## Ticket

{[TICKET-ID](URL), or omit if no ticket.}
```

Omit `Relevant Tests` if there's nothing meaningful to show (config tweak, rename). Omit `Ticket` if there's no ticket. Add `Known Issues` only if shipping with failures or unmet AC.

Adapt to CLAUDE.md PR template if one exists; the above is the fallback.

### Present for review

Show the commit message, PR title, PR description, and base/head branches. Ask: ship, revise, or abort? Loop revisions until the user ships or aborts.

---

## Ship

Execute in sequence. Stop on any failure and surface it.

1. **Stage** — all tracked changes except task files, plan files, `.env`, and secrets.
2. **Commit** — with the approved message.
3. **Push** — `git push -u origin {branch}`. On failure, surface the error and ask.
4. **Create PR** — via `gh pr create`. If `gh` is unavailable, surface the description for manual creation.
5. **Done** — print commit hash, branch, base, and PR URL. Note that task and plan files were not committed.

---

## Guardrails

- **Never force-push.** Surface the reason; the user decides.
- **Never commit task or plan files.** Work scaffolding, not deliverables.
- **Never commit .env, credentials, or secrets.** Warn and exclude.
- **Never skip checks silently.** If they fail, the user decides.
- **Every gate requires explicit approval.** Checks, AC, draft, ship — the user says yes at each.
- **Commit message is the message.** No trailers, attribution lines, or metadata appended beyond what the user approved.
- **Adapt to conventions.** CLAUDE.md style, PR template, branch naming — follow what exists.
