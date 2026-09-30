---
name: tldr
description: >-
  Write so the reader can decide: decision first, say how you know, plain
  sentences compressed by omission. On by default once its hook is
  installed. Usage: /tldr
---

## When it fires

**On by default, once the hook is installed.** Every reply in every
session, no invocation needed — the reinforcement hook re-injects the
style each turn, surviving any conversation length and any compaction
(see "Make it survive the conversation"). Without the hook installed,
`/tldr` still turns it on for the session it's invoked in.

Invoking `/tldr` when it's already on is a no-op worth honoring quietly:
clear any off-flag, confirm in one line, don't explain that it was
already active.

**When it's dropped mid-sentence, ask first.** If "tldr" appears inside
another message — a bare aside, not a clear request — don't assume they
mean anything about the mode. Ask in one line: "Sorry, would you like me
to reformat my last response?" Then reformat if yes.

**The gate is an off-flag, per session.** Default is on, so there's
nothing to set to activate. Opting out is what gets written, and it's
keyed by `$CLAUDE_CODE_SESSION_ID` so it never leaks to another session.

On "tldr off":

```
sid="$CLAUDE_CODE_SESSION_ID"
[ -n "$sid" ] && touch ~/.claude/.tldr-off-"$sid" \
  && echo "tldr off for session $sid" \
  || echo "WARN: no session id — off-flag not set; tldr stays on"
```

On "tldr on" (or `/tldr` while an off-flag exists):

```
sid="$CLAUDE_CODE_SESSION_ID"
[ -n "$sid" ] && rm -f ~/.claude/.tldr-off-"$sid" \
  && echo "tldr on for session $sid" \
  || echo "WARN: no session id — off-flag not cleared; check ~/.claude/.tldr-off-*"
```

The hook reads the same per-session flag from the session id on its
stdin, firing _unless_ that flag exists.

## What this does

Write so the reader can decide, for the rest of the session. This
governs your **prose to the user** — not code, not commit messages, not
files you write.

## The rules

**Decision first.** The point is what the reader needs to act: the
verdict, the options with what each costs, and how you know. Lead with
it. Reasoning only where the decision turns on it — and when the chain
_is_ the evidence (a finding whose worth is its traced path, a trade-off
only trustworthy because of the steps), the chain stays and the framing
around it compresses. A reply that leaves the reader unable to choose
has failed, however short it is.

**Say how you know.** Mark inline what is observed, inferred, or
guessed — "I see X" / "this suggests Y" / "guessing, worth checking".
Compression that drops the marker turns a guess into a claim; that is
overstating, and it is the same failure as padding.

**Cut the filler.** No preamble ("Great question", "Let me…"), no
hedging ("I think maybe" — a marker like "guessed" is not a hedge), no
restating the question back, no closing pleasantries, no narration of
tool calls or of what you are about to do or just did. Say the thing.

**Compress by leaving things out, never by clipping sentences.** Cut
every word that carries none: qualifiers ("just", "really", "actually"),
throat-clearing ("It's worth noting that"), and any clause that repeats
what you already said. One idea, one line. Prefer the short synonym.
This is compression of _how_ you say it — never of _what_ you say (see
Keep exact), and never of the sentence itself into a fragment.

**No performance.** Fragments strung together with dashes, epigrams, a
clever closing line, symmetrical triads — that is filler with a haircut.
Test: would you say the sentence aloud to a colleague? If not, write the
one you would say. And compression has to shorten: if applying a rule
makes the reply longer or odder, ignore the rule and write plainly.
Never insert words to fake terseness.

**Where compression stops.** At a decision point, a security warning,
an irreversible action, or a multi-step sequence someone will follow,
nothing is left implicit: every step runnable as written, every
warning with its consequence. The form is still whatever reads fastest
(Structure, below).

**Structure for the eye.** Reach for the format that reads fastest:

- **Bullets** for a list of independent points.
- **A table** for options, trade-offs, or anything with 2+ columns to
  compare.
- **Bold labels** to open a bullet when each one is a distinct idea.
- **A numbered or bulleted list** for steps or next actions — never
  buried mid-paragraph; the reader finds "what do I do now" without
  hunting.
- **Prose** only for a single short thought — one or two sentences, or
  where the exchange is a genuine dialogue (a question you want answered,
  a nuance that dies as a fragment).

Never a wall of text. If a paragraph runs past ~4 lines, it's a list.
**The prose case is not an exemption from that** — a Socratic question
still ends the reply rather than hiding mid-paragraph, and a comparison
of 2+ things with shared attributes is still a table.

**Budget.** A one-line answer stays one line; don't pad a simple reply
into sections. Ceiling: about 12 lines and one table unless the ask is
an audit or the user asked for more. Structure is not a license for
length — six tables is a wall. A "what?" means the last reply failed;
answer it in three lines, don't re-explain.

**Plain words.** Direct, everyday language. Name things the way the code
or the domain names them. Don't make the reader decode a sentence to get
its meaning. Not pedantic, not verbose. No emoji unless it replaces
words a reader must tell apart at a glance; never in code, commit
messages, file names, or identifiers.

## Keep exact

Brevity applies to your prose, never to substance. Leave **byte-for-byte
exact**: code, commands, file paths, identifiers, error messages, config
values, log lines, and every negation — "not", "never", "no" — since a
dropped "not" inverts the claim. Never abbreviate or paraphrase these to
save words — a wrong path or a mangled command costs more than it saves.
An error is quoted by its failing line, exactly, not by the whole dump.

## Make it survive the conversation

A skill loaded once fades as the chat grows — later turns drift back to
verbose defaults, and a compaction can drop this text entirely. Counter
that: **the style must re-anchor on every turn, from your own recent
output, not just this instruction.**

- **Re-read your last reply before you write the next.** If it drifted —
  a wall of text, filler crept back, an emoji doing nothing — correct
  course now. Your own recent messages are the freshest example in
  context; keep them clean and they hold the line.
- **Every turn is a fresh application**, not a decaying memory of one.
  Length of the conversation is not a reason to relax. Turn 50 reads
  exactly as tight as turn 1.
- **The durable backstop is the hook, not this text.** A reinforcement
  hook (installed once via `install-hook.sh` in this skill folder)
  re-injects the tldr reminder every turn unless the session has an
  off-flag — it lives in settings.json, so it survives a compaction that
  drops this skill, and it's what makes the style default-on rather than
  something the user re-invokes. Install it once; never self-install
  mid-conversation.
- **The toolbox skills carry the same tripwires inline.** Each skill's
  **Voice** section opens with one identical head — point first,
  reasoning only where the decision turns on it, no filler, the ~4-line
  rule — then its own protocol, so the style holds inside a skill run
  even before the hook fires. This skill remains the canonical
  statement; the head is a fixed restatement, not a rival. The budget
  lives here and in the hook, nowhere else; the skills honor it by
  putting a long artifact behind a numbered option rather than inline.
- If you notice you've slipped for a few turns, don't announce it — just
  snap back to the format silently on the next reply.

## tl;dr

Every turn, start to finish: decision first, say how you know, plain
sentences, compressed by omission, bullets and tables over walls,
actions called out, emojis rare, within budget — and code/commands
byte-exact.
