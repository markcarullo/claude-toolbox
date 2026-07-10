#!/usr/bin/env bash
#
# tldr — install the reinforcement hook (run once per machine)
#
# The tldr SKILL.md carries the style rules and re-anchors them each turn,
# but a heavy compaction can drop that text from context. This hook is the
# durable backstop: while the flag file exists, it re-injects a one-line
# tldr reminder into every turn — surviving any conversation length and any
# compaction, because it lives in settings.json, not in the context window.
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
FLAG_HINT="$HOME/.claude/.tldr-active-<session_id>"

REMINDER='[tldr mode is ON] Reply in tldr style: point first, hard-compressed, scannable (bullets/tables over walls), action items called out, emojis rare and only to disambiguate. Keep code, commands, paths, and errors byte-exact.'

# The command the hook runs on every UserPromptSubmit. Cheap: read the
# session id from stdin, test one per-session flag file. Fires ONLY for the
# session whose flag exists — tldr never leaks into other sessions.
# Silent (exit 0) when this session's flag is absent.
#
# The leading `# tldr-reinforce-hook` is a sentinel: uninstall matches OUR
# hook by this exact token, never by a broad substring that could hit a
# user's own hook.
HOOK_CMD='# tldr-reinforce-hook
sid=$(jq -r ".session_id // empty"); [ -n "$sid" ] && [ -f "$HOME/.claude/.tldr-active-$sid" ] && printf '\''{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"'"$REMINDER"'"}}'\''; true'

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
echo "   Activate with /tldr — it writes a per-session flag $FLAG_HINT,"
echo "   so tldr affects only the session where you invoked it."
echo "   Turn off with 'tldr off' (removes that session's flag);"
echo "   remove the hook entirely with bash uninstall-hook.sh."
