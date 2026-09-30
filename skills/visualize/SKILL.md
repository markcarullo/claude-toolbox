---
name: visualize
description: "Build one page that leaves you understanding something you didn't — a ticket, a domain concept, or a decision. Grounds every claim in a source, juxtaposes rather than narrates, and marks what is still unknown. Published as an Artifact and revised in place across the conversation. Usage: /visualize [what you want to understand]"
---

# visualize

**The page is a mental model you could redraw from memory.** Not a report you re-open. You arrive not understanding something; you leave able to explain it to someone else, and able to say where your map ends.

Runs beside `unpack`, not inside the pipeline. `unpack` owns the dialogue — you retain what you surface. `visualize` owns the page — for when the thing has too many moving parts to hold in prose, or the parts relate in a shape a conversation can't draw. Reach for it when you catch yourself asking "how does this relate to that", "status quo vs after", or "explain this to me as a newbie". Reach for `unpack` when the gap is one concept deep.

The audience is **you**, alone, later. That is the whole difference from a handover doc: no reader to impress, no claim to defend, nothing to hedge. A page that implies completeness it doesn't have is the thing that makes a competent person feel like a fraud.

`visualize` never fills a gap with a plausible sentence — a gap is content, rendered as a gap.

**Voice.** Point first; reasoning only where the decision turns on it. No preamble, no hedging, no restating the ask. Past ~4 lines a paragraph becomes a list. Here the point is what the page shows, what it couldn't establish. Minimize the play-by-play — the value is the page, not the research that got there. One line per source read, and only when a source failed or contradicted another. Numbered options for fast-loop discrete asks (`[1] X  [2] Y  [3] Z`); `AskUserQuestion` for ambiguous lens picks or comparable previews; open-ended asks stay prose. Clickable file refs when grounding in code (`[cache.ts:42](src/cache.ts#L42)`). Distinguish observed / inferred / guessed — a relationship you read in code is observed, one you believe from naming is inferred, and a guess doesn't go on the page.
✓ `Published — cache-invalidation. Invalidation is server-driven only; the client mirror at useCache.ts:88 is advisory. Two ACs had no code path I could find — they're in the Not established band.`  ✗ `I've gone ahead and created a comprehensive visualization for you that should hopefully help clarify how the cache invalidation mechanism works across the stack!`

## Target

$ARGUMENTS

---

## On entry

### Pick the lens

Three different pages. Picking wrong produces a page that answers a question you didn't ask.

| Lens | The question it answers | Lives for | Named after |
| --- | --- | --- | --- |
| **task** | What is this ticket asking, where are we against it, what's left | Until the PR merges | The ticket |
| **domain** *(default)* | What is this thing, how do its parts relate, why does it exist | Outlives the ticket | The concept |
| **decision** | What are the options, what does each buy and cost, which is recommended | Until the call is made | The question |

**Warm start is the common case.** Most invocations come mid-session, from inside another skill, with the context already loaded. Then the lens is whatever the conversation has been circling — take it and skip the order below.

Cold start — `$ARGUMENTS` is empty or ambiguous and the session has nothing:

1. A ticket key, or "the ACs" / "what this JIRA asks" / "where are we" → **task**.
2. Two or more alternatives in play — a reviewer's shape vs yours, "should we X or Y" → **decision**.
3. A noun you don't yet own — a concept, an entity, a flow, a subsystem → **domain**.
4. Nothing decides it → ask with numbered options. Never build all three into one page.

### Gather the sources

Read in parallel — but only what the session hasn't already established. A source read earlier in the conversation is read; re-reading burns context and risks contradicting what the session settled. Report what failed rather than substituting for it.

- **Ticket** — the issue, its parent epic or feature, and its comments verbatim. The *why* usually lives in a comment, not the description.
- **Code** — the actual paths, read whole enough to trace a relationship. A grep hit is not a relationship.
- **Change** — `git diff` against the base, or `gh pr diff`, when the lens is task or decision.
- **Review and chat** — PR comments, pasted chat. When the page exists to decode what a person is asking for, their words are the primary source and get quoted, not paraphrased.
- **Docs** — the team's doc system, `CLAUDE.md`, in-repo design notes.

Read repo-root `CLAUDE.md` if present — its conventions decide which relationships are notable and which are just how this codebase is written everywhere.

**When a source contradicts another, that contradiction is content.** It goes on the page, both sides attributed. It does not get resolved silently.

---

## The six rules of the page

Everything below is non-negotiable.

1. **Ground every claim.** Each assertion ties to a source — `file.ts:42`, a ticket key, a commit, a quoted comment. A claim you can't source either comes off the page or moves to *Not established*.
2. **Juxtapose, don't narrate.** Status quo beside after. Their shape beside yours. AC beside the code that satisfies it. Side by side in a table or paired panels — never two paragraphs the reader has to hold in their head at once.
3. **Show the relationships.** The page exists instead of a list because objects relate. A diagram earns its place exactly when a list can't show the relationship; otherwise a table is faster.
4. **Pace it.** One screen orients — what this is, why it matters, the shape in a sentence. Depth after, in layers. Never open on nuance.
5. **Gloss the jargon.** Every domain term gets a short inline gloss on first use, every time, even the ones you now know. The page is for the version of you who has been away from it for a month.
6. **Mark the edges.** A visible *Not established* band, last before the recall block: what you looked for and couldn't find, what the sources disagree on, what is inference rather than observation. Never empty by default — if it is empty, say in chat that it genuinely is.

**Decision pages carry three things the other lenses don't:** the options side by side with what each buys and costs, the criterion that separates them, and what would change the call. A recommendation without the criterion is an opinion.

### The recall block

The page ends with **three questions it answers** — the ones you'd actually be asked: in standup, by a reviewer, by the person who owns the next ticket. No answers printed beside them.

Optional, and the first thing to cut if it goes unused — rule 6 carries the same load with more evidence behind it. While it earns its place: if you can answer all three without scrolling up, you own it; the one you can't is the revision instruction.

---

## Build

**Load `artifact-design` before writing a line of the page.** Load `artifact-diagramming` too when rule 3 says a diagram earns its place.

Write to the scratchpad, then publish with `Artifact`.

`visualize` depends on the `Artifact` tool. Where it isn't available, write the same page as a local `.html` file and say so — every rule above still applies.

- **Name the file after the subject, not the ticket** — `cache-invalidation.html`, `retry-budget.html`, `rejection-ownership.html`. Task-lens pages are the exception; they take the ticket key. A domain page named after a ticket is unfindable in three weeks.
- **The title is the subject.** Two to four words, the thing itself, no explainer clause.
- **One page per subject.** A second concept means a second page, linked, not a longer page.

### Verify before you present

Run this pass before publishing, every time. It is the pass you would otherwise ask for by hand.

- Every claim on the page → name its source. Unsourced claims come off or move to *Not established*.
- Every quoted person → quoted verbatim, attributed.
- Every code reference → the line still says what the page says it says.
- Every juxtaposition → both sides real, neither straw-manned.
- Every domain term → glossed on first use.

**Report the pass in one line, and name what didn't survive it.** A silent verify is worth nothing to a reader trying to calibrate how much to trust the page.

### Revise in place

The page is a living document, not a deliverable. Revisions republish **the same artifact** — same URL, same tab, no orphaned versions. A new URL is a new subject, never a new draft.

**Across sessions the scratchpad path changes, so the path alone won't find the page.** Before publishing something that may already exist: `Artifact action: "list"`, match on the subject name, then `action: "read"` it and build the revision on what comes back, republishing with that `url`.

Revision instructions come in three shapes, and each has a different fix:

| You say | It means | The fix |
| --- | --- | --- |
| "I don't follow section X" | Pacing or gloss failed | Layer it — orient before nuance, gloss the term |
| "This doesn't match what I see" | Grounding failed | Re-read the source; correct or move to *Not established* |
| "Add Y" | Scope grew | New section if same subject, new page if not |

---

## Outcome

The link, one line naming what the page establishes, one line naming what it couldn't, and **one question** — the recall question you'd least expect to answer well.

Not a recap of the page.
