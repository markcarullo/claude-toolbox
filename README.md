# claude-toolbox

Claude Code skills that take you from a JIRA ticket to an open PR.

Each stage is its own skill, with a gate you control. Skills hand off context through files in your working directory and pick up your project's conventions from `CLAUDE.md`.

## Skills

| Skill      | Description                                                                         |
| ---------- | ----------------------------------------------------------------------------------- |
| `/start`   | Fetches a JIRA ticket, scopes it, sets up a worktree or branch with a task file     |
| `/unpack`  | Runs a Socratic dialogue — studies a topic, or shapes a plan and writes it to a file |
| `/collab`  | Pairs on the implementation, calibrating from a nudge to taking the keyboard        |
| `/examine` | Runs an Advocate/Adversary loop to pressure-test code or a plan                     |
| `/ship`    | Runs checks, verifies AC, drafts the commit (and PR if pushing), gates each write   |
| `/peer`    | Reviews a teammate's PR — never writes to GitHub                                    |

## Workflow

```
/start <ticket>     Pick up a ticket, set up the workspace
        ↓
/unpack             Understand the problem, shape the approach
        ↓
/collab             Pair on the implementation
        ↓
/examine            Pressure-test before shipping
        ↓
/ship               Checks, commit, push, PR handoff

/peer <PR>          Review someone else's work
```

The diagram shows the full path, but `/unpack`, `/collab`, and `/examine` work on their own — no ticket needed.

### How the skills connect

Skills share context through two files in the working directory:

- `/start` writes `{TICKET}-TASK.md` — ticket summary, AC, starting points
- `/unpack` reads the task file; in plan mode, writes `{TICKET}-PLAN.md` — approach, steps, assumptions
- `/collab` reads both files for context
- `/examine` reads the plan file by default, or auto-detects from staged changes and conversation
- `/ship` reads the task file to verify AC, and keeps both files out of commits

If your repo has a `CLAUDE.md`, skills follow the conventions it documents — branch naming, commit style, PR template, test commands, codebase patterns.

## What it looks like

`/start` presents a scoped summary before setting up the workspace:

```
TICKET     PROJ-1234: Fix stale cache on dashboard refresh
TYPE       Bug
BRANCH     fix/stale-cache-dashboard-refresh

SUMMARY    The dashboard shows stale data after a manual refresh because
           the cache key isn't invalidated when the user triggers a reload.
           The bug is scoped to the dashboard polling layer.

LEADS      2

[1] GO    [2] REVIEW BRIEF    [3] REJECT
```

`/ship` maps each acceptance criterion to the diff before drafting the commit message:

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
- [Atlassian MCP](https://marketplace.anthropic.com/) — connect via the Anthropic marketplace. `/start` uses it to fetch tickets; `/peer` uses it to look up linked tickets.
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
