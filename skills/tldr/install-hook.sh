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

# Structure clause is conditional ("when structure reads faster") rather than
# absolute: this reminder now fires during dialogue skills like /unpack too,
# where bulleting a Socratic question would be wrong. Walls stay banned; the
# choice of bullets vs sentences is left to the content.
REMINDER='[tldr mode is ON] Reply in tldr style: point first, hard-compressed, no filler; structure for the eye when structure reads faster (bullets/tables over walls — never a wall either way), action items called out, emojis rare and only to disambiguate. Keep code, commands, paths, and errors byte-exact.'

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

# Merge: append our UserPromptSubmit hook, preserving every existing hook.
# Dedup by command string so re-running doesn't stack duplicates.
UPDATED="$(printf '%s' "$BASE" | jq --arg cmd "$HOOK_CMD" '
  .hooks //= {}
  | .hooks.UserPromptSubmit //= []
  | if any(.hooks.UserPromptSubmit[]?; .hooks[]?.command == $cmd)
    then .
    else .hooks.UserPromptSubmit += [{"hooks": [{"type": "command", "command": $cmd}]}]
    end
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
