#!/usr/bin/env bash
#
# tldr — remove the reinforcement hook and the flag. Idempotent.
#
# Usage: bash uninstall-hook.sh

set -euo pipefail

: "${HOME:?HOME is not set — cannot locate ~/.claude. Set HOME and re-run.}"

SETTINGS="$HOME/.claude/settings.json"

# Clear every per-session flag (glob; the nullglob guard avoids a literal
# match when none exist). Both names: .tldr-off-* is the current opt-out flag,
# .tldr-active-* the opt-in flag from before tldr became default-on — clearing
# it too keeps an upgrade from leaving orphans behind.
shopt -s nullglob
rm -f "$HOME"/.claude/.tldr-off-* "$HOME"/.claude/.tldr-active-*
shopt -u nullglob

if [ ! -f "$SETTINGS" ]; then
  echo "✅ nothing to remove (no settings file); flag cleared."
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required. Install jq and re-run." >&2
  exit 1
fi

if ! jq empty "$SETTINGS" >/dev/null 2>&1; then
  echo "error: $SETTINGS is not valid JSON. Fix it first." >&2
  exit 1
fi

# Drop only OUR hook, matched by the unique sentinel token install writes as
# the command's first line. Matching the sentinel (not a broad substring)
# means a user's own hook that merely mentions the flag path is never touched.
# Prune the array/key if it ends up empty so we don't leave hollow structure.
UPDATED="$(jq '
  if .hooks.UserPromptSubmit then
    .hooks.UserPromptSubmit |= map(select(
      (.hooks // []) | any(.command? // "" | startswith("# tldr-reinforce-hook")) | not
    ))
    | if (.hooks.UserPromptSubmit | length) == 0 then del(.hooks.UserPromptSubmit) else . end
  else . end
' "$SETTINGS")"

TMP="$(mktemp "${SETTINGS}.XXXXXX")"
printf '%s\n' "$UPDATED" | jq . > "$TMP"
mv "$TMP" "$SETTINGS"

echo "✅ tldr hook removed from $SETTINGS; flag cleared."
echo "   Restart Claude Code (or open /hooks once) so the watcher drops it."
