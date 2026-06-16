# claude-toolbox

Claude Code skills that take you from a JIRA ticket to an open PR.

Each stage is its own skill, with a gate you control. Skills hand off context through files in your working directory and pick up your project's conventions from `CLAUDE.md`.

## Skills

| Skill      | Description                                                                         |
| ---------- | ----------------------------------------------------------------------------------- |
| `/start`   | Fetches a JIRA ticket, scopes it, sets up a worktree or branch with a task file     |
| `/unpack`  | Runs a Socratic dialogue — studies a topic, or shapes a plan and writes it to a file |
| `/tdd`     | Turns the AC into failing tests, confirms each is RED for the right reason — test files only |
| `/collab`  | Pairs on the implementation, calibrating from a nudge to taking the keyboard        |
| `/break`   | Pre-ship adversarial gate — an Attacker proposes breakages, a Skeptic refutes reachability; report-only |
| `/examine` | Runs an Advocate/Adversary loop to pressure-test code, a plan, or a doc             |
| `/ship`    | Runs checks, verifies AC, drafts the commit (and PR if pushing), gates each write   |
| `/peer`    | Reviews a teammate's PR — never writes to GitHub                                    |

## Workflow

```
/start <ticket>     Pick up a ticket, set up the workspace
        ↓
/unpack             Understand the problem, shape the approach
        ↓
/tdd                Turn the AC into failing tests before building
        ↓
/collab             Pair on the implementation
        ↓
/break or /examine  Attack the change, or pressure-test the reasoning
        ↓
/ship               Checks, commit, push, PR handoff

/peer <PR>          Review someone else's work
```

The diagram shows the full path, but `/unpack`, `/tdd`, `/collab`, `/break`, and `/examine` work on their own — no ticket needed.

### How the skills connect

Skills share context through two files in the working directory:

- `/start` writes `{TICKET}-TASK.md` — ticket summary, AC, starting points
- `/unpack` reads the task file; in plan mode, writes `{TICKET}-PLAN.md` — approach, steps, assumptions
- `/tdd` reads both files to turn the AC into failing tests; defaults to them, or takes a behavior in prose
- `/collab` reads both files for context
- `/break` defaults to the uncommitted diff against the task/plan; also takes an area, a PR, or a workflow
- `/examine` reads the plan file by default, or auto-detects from staged changes, recently edited docs, and conversation
- `/ship` reads the task file to verify AC, and keeps both files out of commits

If your repo has a `CLAUDE.md`, skills follow the conventions it documents — branch naming, commit style, PR template, test commands, codebase patterns.

## What it looks like

One ticket through the whole path — `PROJ-1234: Fix stale cache on dashboard refresh`.

**`/start`** scopes the ticket and presents the brief in a dialog — approve, revise, or reject — before setting up the workspace:

```
TICKET     PROJ-1234: Fix stale cache on dashboard refresh
TYPE       Bug
BRANCH     fix/stale-cache-dashboard-refresh

SUMMARY    The dashboard shows stale data after a manual refresh because
           the cache key isn't invalidated when the user triggers a reload.
           The bug is scoped to the dashboard polling layer.

LEADS      2

[ GO ]    [ REVISE ]    [ REJECT ]
```

**`/unpack`** talks the problem through, then writes the approach to `PROJ-1234-PLAN.md`:

```
## Approach
Invalidate the cache key in the refresh handler, not on the next poll
tick — the stale read happens in the gap between them.

## Steps
1. invalidate(key) in the refresh handler
2. reset the poll cursor so the next fetch is authoritative

## Testing
- unit: refresh invalidates the key
- unit: reload returns fresh data
```

**`/tdd`** turns each acceptance criterion into a failing test and confirms every one is red for the right reason — before any code is written:

```
RED CONFIRMATION

  #  Test                                  Status
  1  cache invalidated on manual refresh   ✓ red (assertion: key still cached)
  2  dashboard shows fresh data on reload  ✓ red (assertion: got stale body, want fresh)

All 2 red for the right reason — handing off to /collab.
```

**`/collab`** pairs on the implementation, then closes with what landed:

```
Done:
  • invalidate(key) in the refresh handler  → src/cache.ts:48
  • poll cursor resets after invalidation    → src/dashboard.ts:30
  • tests 1 & 2 green

Loose ends: loading indicator has no error state yet
```

**`/break`** attacks the change before it ships, reporting only breakages it can trace a path to (`/examine` is the alternative here — it returns a recommendation instead of an attack):

```
1 breakage survived refutation, 0 killed, 1 unverified.

── Confirmed ──

[1] Major · refresh during an in-flight poll reads a half-cleared cache
    Where:   src/cache.ts:48
    Break:   invalidate() clears the key mid-poll; the poll resolves and re-stores stale data
    Trigger: a manual refresh fires while a poll is still awaiting
    Path:    poll started at dashboard.ts:30, not cancelled on refresh
    Fix direction: cancel or version the in-flight poll on invalidate
```

**`/ship`** maps each acceptance criterion to the diff, then drafts the commit:

```
✓  Cache invalidated on manual refresh
   → src/cache.ts: invalidate() call added in refresh handler
✓  Dashboard shows fresh data after reload
   → src/dashboard.ts: polling resets after invalidation
~  Loading indicator during refresh
   → partial: spinner added, no error state
```

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) or Claude Desktop
- [Atlassian MCP](https://marketplace.anthropic.com/) — connect via the Anthropic marketplace. `/start` uses it to fetch tickets; `/peer` uses it to look up linked tickets, falling back to `gh` if absent.
- [GitHub CLI](https://cli.github.com/) (`gh`) — installed and authenticated. Required by `/ship` and `/peer`. `/collab` uses it to surface open PR comments; skips silently if absent.

## Assumptions

- The working directory is a git repository on **GitHub**. `/ship` and `/peer` shell out to `gh`; GitLab and Bitbucket aren't supported.
- `/start` opens the workspace in [VS Code](https://code.visualstudio.com/) via the `code` CLI. Adapt or skip if you use a different editor.

## Installation

From the repo root:

```bash
mkdir -p ~/.claude/skills
cp -r skills/* ~/.claude/skills/
```
