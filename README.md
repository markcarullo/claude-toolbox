# claude-toolbox

Claude Code skills that take you from a JIRA ticket to a merged PR.

Each stage has its own gate, skills hand off context through files, and they pick up your project's conventions along the way.

## Skills

| Skill        | Description                                                                             |
| ------------ | --------------------------------------------------------------------------------------- |
| `/start`     | Fetch a JIRA ticket, scope it against the codebase, set up a workspace with a task file |
| `/think`     | Socratic study mode or plan mode — deepens understanding or pressure-tests decisions    |
| `/collab`    | Collaborative coding partner that calibrates from a nudge to taking the keyboard        |
| `/challenge` | Adversarial Advocate/Adversary loop to pressure-test code or a plan                     |
| `/ship`      | Run checks, verify AC, draft commit and PR, ship with approval at each gate             |
| `/peer`      | Review a teammate's PR — understand it, surface strengths and weaknesses                |

### Workflow

```
/start <ticket>     Pick up a ticket, set up the workspace
        ↓
/think              Think it through, plan the approach
        ↓
/collab             Pair on the implementation
        ↓
/challenge          Pressure-test before shipping
        ↓
/ship               Checks, commit, PR

/peer <PR>          Review someone else's work
```

The diagram shows the full sequence, but `/think`, `/collab`, and `/challenge` also work independently — you don't need a ticket to use them.

### How the skills connect

The skills pass context through files in the working directory:

- `/start` spins up a worktree or branch, primed with `{TICKET}-TASK.md` — ticket summary, AC, starting points
- `/think` reads the task file; in plan mode, writes `{TICKET}-PLAN.md` — approach, steps, assumptions
- `/collab` and `/ship` read both files for context
- `/challenge` reads the plan file, or targets whatever you point it at
- `/ship` excludes task and plan files from commits automatically

If your project has a `CLAUDE.md`, `/start`, `/ship`, and `/challenge` adapt to its conventions (branch naming, commit style, PR templates, test commands, codebase patterns).

## What it looks like

`/start` scopes the ticket and presents a summary before setting up the workspace:

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

`/ship` maps each acceptance criterion to diff evidence before drafting the PR:

```
AC VERIFICATION

✓  Cache invalidated on manual refresh → src/cache.ts: added invalidate() call in refresh handler
✓  Dashboard shows fresh data after reload → src/dashboard.ts: polling resets after invalidation
~  Loading indicator during refresh → partial — spinner added but no error state
```

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) or Claude Desktop
- [Atlassian MCP](https://marketplace.anthropic.com/) — connect via the Anthropic marketplace. JIRA-first by design.
  `/start` uses it to fetch tickets; `/peer` can use it to look up linked tickets.
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated (for `/ship` and `/peer`)

## Assumptions

- The skills assume the working directory is a git repository.
- `/start` assumes [VS Code](https://code.visualstudio.com/) (`code` CLI) to open the workspace. Adapt if you use a different editor.

## Installation

Copy the skills into your `~/.claude/` directory:

```bash
mkdir -p ~/.claude/skills
cp -r skills/* ~/.claude/skills/
```
