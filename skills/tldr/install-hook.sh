#!/usr/bin/env bash
#
# tldr — install the reinforcement hook (run once per machine)
#
# The tldr SKILL.md carries the style rules and re-anchors them each turn,
# but a heavy compaction can drop that text from context. This hook is the
# durable backstop: it re-injects a one-line tldr reminder into every turn —
# surviving any conversation length and any compaction, because it lives in
# settings.json, not in the context window.
#
# tldr is ON BY DEFAULT once installed: every session, no /tldr needed. The
# gate is inverted — the hook fires UNLESS this session has an off-flag, so
# 'tldr off' opts a single session out and never leaks to the others.
#
# Idempotent: safe to run repeatedly. Deterministic jq merge — never an
# LLM-authored edit to your settings. After it runs, restart Claude Code
# (or open /hooks once) so the watcher loads the new hook.
#
# Usage:   bash install-hook.sh
# Undo:    bash uninstall-hook.sh

set -euo pipefail

: "${HOME:?HOME is not set — cannot locate ~/.claude. Set HOME and re-run.}"

SETTINGS="$HOME/.claude/settings.json"
FLAG_HINT="$HOME/.claude/.tldr-off-<session_id>"

# The structure clause is conditional ("only where they read faster than
# sentences"), not absolute: this fires during dialogue skills like /unpack too, where
# bulleting a Socratic question would be wrong. Walls stay banned; bullets
# vs sentences follows the content.
# No double quotes, single quotes, backslashes or % in REMINDER: it is spliced
# into a printf format string inside a JSON literal below.
REMINDER='[tldr mode is ON] Write so the reader can decide. Lead with the call. When there is a real choice, name each live option and its cost in one line each; otherwise no table. Mark inline what is observed, inferred, or guessed; no separate section for it. Reasoning only where the decision turns on it, and nothing the reader did not ask for. Plain sentences: no clipped fragments, no dash-chains, no aphorisms, no closing flourish. At a decision point, a warning, an irreversible action, or a multi-step sequence, nothing is left implicit: every step runnable as written, every warning with its consequence. No narration of what you are about to do or just did. Bullets and tables only where they read faster than sentences. Code, commands, paths, and negations byte-exact; for an error, the failing line exactly, not the dump. Budget: about 12 lines and one table; go past it only when the ask is an audit or the reader asked for more. ✓ Stale after refresh: the key is never invalidated (cache.ts:48, observed). Fix there, or in the poll tick, which adds a second race.  ✗ Great question, so there are a few things going on here that are worth walking through. A bare what? means the last reply failed: answer in three lines, do not re-explain.'

# The command the hook runs on every UserPromptSubmit. Cheap: read the
# session id from stdin, test one per-session off-flag. Fires for EVERY
# session UNLESS that session opted out — tldr is the default, and an opt-out
# never leaks into other sessions. Silent (exit 0) when the off-flag exists.
#
# The leading `# tldr-reinforce-hook` is a sentinel: uninstall matches OUR
# hook by this exact token, never by a broad substring that could hit a
# user's own hook.
HOOK_CMD='# tldr-reinforce-hook
sid=$(jq -r ".session_id // empty"); [ -f "$HOME/.claude/.tldr-off-$sid" ] || printf '\''{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"'"$REMINDER"'"}}'\''; true'

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required (deterministic merge). Install jq and re-run." >&2
  exit 1
fi

# Start from existing settings, or an empty object if none.
if [ -f "$SETTINGS" ]; then
  if ! jq empty "$SETTINGS" >/dev/null 2>&1; then
    echo "error: $SETTINGS is not valid JSON. Fix it before installing." >&2
    exit 1
  fi
  BASE="$(cat "$SETTINGS")"
else
  mkdir -p "$(dirname "$SETTINGS")"
  BASE='{}'
fi

# Merge: replace our UserPromptSubmit hook, preserving every other hook.
# Matched by the sentinel, not the full command, so a changed REMINDER
# replaces the old entry instead of stacking a second one.
UPDATED="$(printf '%s' "$BASE" | jq --arg cmd "$HOOK_CMD" '
  .hooks //= {}
  | .hooks.UserPromptSubmit //= []
  | .hooks.UserPromptSubmit |= map(select(
      (.hooks // []) | any(.command? // "" | startswith("# tldr-reinforce-hook")) | not
    ))
  | .hooks.UserPromptSubmit += [{"hooks": [{"type": "command", "command": $cmd}]}]
')"

# Write atomically via a temp file in the same dir.
TMP="$(mktemp "${SETTINGS}.XXXXXX")"
printf '%s\n' "$UPDATED" | jq . > "$TMP"
mv "$TMP" "$SETTINGS"

echo "✅ tldr hook installed in $SETTINGS"
echo "   Restart Claude Code (or open /hooks once) so the watcher loads it."
echo "   tldr is now ON BY DEFAULT in every session — no /tldr needed."
echo "   Opt one session out with 'tldr off' (writes $FLAG_HINT);"
echo "   'tldr on' removes that flag. Both are per session, never global."
echo "   Remove the hook entirely with bash uninstall-hook.sh."
