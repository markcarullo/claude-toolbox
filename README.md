# claude-toolbox

Claude Code skills that take you from a JIRA ticket to an open PR, plus three utilities that work in any session.

Each stage is its own skill, with a gate you control. Skills hand off context through files in your working directory and pick up your project's conventions from `CLAUDE.md`.

## Skills

| Skill      | Description                                                                         |
| ---------- | ----------------------------------------------------------------------------------- |
| `/start`   | Fetches a JIRA ticket, scopes it, sets up a worktree or branch with a task file     |
| `/unpack`  | Runs a Socratic dialogue — studies a topic, or shapes a plan and writes it to a file |
| `/tdd`     | Turns the AC into failing tests, confirms each is RED for the right reason — test files only |
| `/converge` | Descends on the implementation autonomously — measure, change, re-measure against tests, typecheck, and lint; stops with a named reason when it stalls |
| `/minimal` | Reduces the change to what's load-bearing for its consumer — cuts are evidence-bound and gated |
| `/break`   | Pre-ship adversarial gate — an Attacker proposes breakages, a Skeptic refutes reachability; survivors leave with a fix and the test that names it |
| `/examine` | Runs an Advocate/Adversary loop to pressure-test code, a plan, or an asserting doc  |
| `/ship`    | Runs checks, verifies AC, then reports only or drafts the commit (and PR if pushing), gating each write |
| `/peer`    | Reviews a teammate's PR — never writes to GitHub                                    |

## Utilities

Not pipeline stages — invoke any of them in any session, ticket or no ticket.

| Command     | Description                                                                          |
| ----------- | ------------------------------------------------------------------------------------ |
| `/tldr`     | Decision first, plain sentences, compressed by omission — on by default once its hook is installed |
| `/steady`   | Make sure, then move on what's pending — slowly but surely, once certain of the premise |
| `/visualize` | Builds one grounded page — a ticket, a domain concept, or a decision — published as an Artifact and revised in place |

`/tldr`'s style is **built into every skill** — each skill's Voice section opens with the same head (point first, reasoning only where the decision turns on it, no filler, past ~4 lines it's a list), then the protocol that skill needs. The reply budget lives in `/tldr` and its hook, nowhere else. You shouldn't need to ask for it.

For the durable version, install its reinforcement hook once — after the install step below: `bash ~/.claude/skills/tldr/install-hook.sh`. It re-injects the style every turn from `settings.json`, so it survives a compaction that drops the skill text — and it makes tldr **on by default in every session**, no invocation needed. If it doesn't fire, restart Claude Code (or open `/hooks` once) so the watcher picks it up. Opt a single session out with `tldr off`, back in with `tldr on`; both are per session and never global. `uninstall-hook.sh` removes the hook entirely.

`/steady` is a slash command (in `commands/`), your standing reply when a skill asks to proceed. Pass a note to steer it — `/steady skip the docstring`.

`/visualize` sits beside `/unpack` — `/unpack` is the dialogue, `/visualize` is the page, for when the parts relate in a shape a conversation can't draw. Every claim on the page names its source, and what couldn't be established is marked as such rather than smoothed over. It needs the `Artifact` tool; without it the same page is written as a local `.html` file.

## Workflow

```
/start <ticket>     Pick up a ticket, set up the workspace
        ↓
/unpack             Understand the problem, shape the approach
        ↓
/tdd                Turn the AC into failing tests before building
        ↓
/converge           Descend on the implementation
        ↓
/minimal            Cut what doesn't earn its place, tighten what does
        ↓
/break or /examine  Attack the change, or pressure-test the reasoning
        ↓           (already run as /converge's gates — re-run only if /minimal cut code or tests, not just comments and prose)
/ship               Checks, commit, push, PR handoff

/peer <PR>          Review someone else's work
```

The diagram shows the full path, but `/unpack`, `/tdd`, `/converge`, `/minimal`, `/break`, and `/examine` work on their own — no ticket needed.

### How the skills connect

Skills share context through three files in the working directory:

- `/start` writes `{TICKET}-TASK.md` — ticket summary, AC, leads, and a Deferred list (findings parked with a condition) — and opens `{TICKET}-LOG.md`, the decision trail
- `/unpack` reads the task file; in plan mode, writes `{TICKET}-PLAN.md` — approach, steps, assumptions
- `/tdd` reads both files to turn the AC into failing tests; defaults to them, or takes a behavior in prose
- `/converge` reads all three files; the plan's Testing section names the tests in its fitness function and the files the plan names bound its blast radius. `/examine` and `/break` are its fixed gates; `/converge gate on /my-lens` adds a project's own review skill between them
- `/minimal` defaults to the uncommitted diff; also takes a file, an area, or prose. Cuts are gated, rewrites preview as a diff
- `/break` defaults to the uncommitted diff against the task/plan; also takes an area, a PR, or a workflow. Every survivor carries a fix and the test that names it; Apply lands both on your go-ahead
- `/examine` auto-detects a plan, the uncommitted diff (code mode), docs (audit mode), or conversation
- `/ship` reads the task file to verify AC and re-check Deferred items, keeps all three files out of commits, and offers the log's retractions as memories

**The decision log.** `{TICKET}-LOG.md` is the trail of how the ticket was traversed: which headings were taken, which were passed up, which were abandoned. Every skill above, plus `/steady`, appends to it; `/unpack`, `/converge`, and `/examine` read it on entry so a settled fork isn't re-opened and a retracted heading isn't re-proposed. Nothing else reads it on entry; `/ship` harvests its retractions at the end. The current heading stays in the plan. One line per entry, six kinds:

| Line | Written when |
|---|---|
| `enter [skill] target` | a skill starts |
| `outcome [skill] verdict` | a skill ends — tests red, cuts proposed, breakages, ship score |
| `fork#slug chose X over Y — criterion` | a shape-level choice: alternatives that differ in files touched or structure |
| `round [converge] 3 · 4/6 green · 2 files` | each round of `/converge`'s descent — its stall rules count these |
| `retract →#slug reason` | a heading turned out wrong — a user override, a `/converge` stall, `/examine` failing to converge |
| `steer [steady] note` | `/steady` sets the direction — a bare number picks from the options last offered |

Lines are appended from the shell (`>>`), one at a time, never rewritten and never by a subagent — so parallel sessions on the same ticket can't clobber each other. No task file, no log.

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

All 2 red for the right reason — handing off to /converge.
```

**`/converge`** descends on the implementation, then stops with what landed and why it stopped:

```
Converged

Done:
  • invalidate(key) in the refresh handler  → src/cache.ts:48
  • poll cursor resets after invalidation    → src/dashboard.ts:30
Loose ends: loading indicator has no error state yet
Fitness: 2/2 green · typecheck ✓ · lint ✓   Rounds: 4   Gates: examine ✓ · break ✓

Next: /minimal, then /ship
```

**`/break`** attacks the change before it ships, reporting only breakages it can trace a path to — and each survivor leaves with its fix and the test that names it (`/examine` is the alternative here — it returns a recommendation instead of an attack):

```
2 breakages survived refutation, 0 killed, 0 unverified.

── Confirmed ──

| # | Sev | What breaks | Where | Fix |
|---|-----|-------------|-------|-----|
| 1 | Major | refresh during an in-flight poll reads a half-cleared cache | src/cache.ts:48 | version the cache key on invalidate; a stale poll's write is dropped |
| 2 | Minor | refresh mid-fetch shows no pending state, so a failed reload looks done | src/dashboard.ts:30 | add an error branch to the refresh handler that renders on the indicator |

  1 — reachable via: a manual refresh fires while a poll is still awaiting → invalidate() clears the key mid-poll, the poll resolves and re-stores stale data (poll started at dashboard.ts:30, not cancelled on refresh).
      test: refresh while a poll is in flight → the poll's late write does not repopulate the key
  2 — reachable via: the refresh handler has no error branch, so a rejected reload leaves the last-good view with no signal (loose end carried from /converge).
      test: reload rejects → the refresh indicator shows an error state

[1] Apply — fixes and their tests  [2] Tests only — red, for /converge  [3] Write the report doc  [4] Discard
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
- Atlassian MCP — the Atlassian connector in your claude.ai settings, or Atlassian's remote MCP server added with `claude mcp add` (see [Claude Code MCP docs](https://docs.anthropic.com/en/docs/claude-code/mcp)). `/start` uses it to fetch tickets; `/peer` uses it to look up linked tickets, falling back to `gh` if absent.
- [GitHub CLI](https://cli.github.com/) (`gh`) — installed and authenticated. Required by `/ship` and `/peer`.

## Assumptions

- The working directory is a git repository on **GitHub**. `/ship` and `/peer` shell out to `gh`; GitLab and Bitbucket aren't supported.
- `/start` opens the workspace in [VS Code](https://code.visualstudio.com/) via the `code` CLI. Adapt or skip if you use a different editor.

## Installation

From the repo root:

```bash
mkdir -p ~/.claude/skills ~/.claude/commands
cp -r skills/* ~/.claude/skills/
cp commands/* ~/.claude/commands/   # slash commands (e.g. /steady)
```

`/tldr`'s reinforcement hook installs separately — it's what makes the style on-by-default in every session. See Utilities above.

### Developing the toolbox

Symlink instead of copying, so an edit made in either place lands in the repo:

```bash
for d in skills/*/; do n=$(basename "$d"); rm -rf ~/.claude/skills/$n && ln -s "$PWD/skills/$n" ~/.claude/skills/$n; done
ln -sf "$PWD/commands/steady.md" ~/.claude/commands/steady.md
```
