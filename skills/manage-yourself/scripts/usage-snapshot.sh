#!/usr/bin/env bash
# Status line wrapper for the manage-yourself skill.
#
# Claude Code only gives usage limits (rate_limits) to the status line script.
# This wrapper saves them to a small JSON file, which the skill and its
# subagents read with check-usage.sh.
#
# In ~/.claude/settings.json:
#   "statusLine": { "type": "command",
#                   "command": "~/.claude/manage-yourself/usage-snapshot.sh",
#                   "refreshInterval": 60 }
# To keep an existing status line, pass its command as the first argument:
#   "command": "~/.claude/manage-yourself/usage-snapshot.sh '<existing command>'"

set -u
SNAP_DIR="${MANAGE_YOURSELF_DIR:-$HOME/.claude/manage-yourself}"
SNAP="$SNAP_DIR/usage-snapshot.json"

input=$(cat)

# Save only the rate limit data, and only when this update carries it.
if command -v jq >/dev/null 2>&1; then
  limits=$(printf '%s' "$input" | jq -c 'select(.rate_limits != null and .rate_limits != {})
    | {captured_at: (now | floor), rate_limits: .rate_limits}' 2>/dev/null)
  if [ -n "$limits" ]; then
    mkdir -p "$SNAP_DIR"
    tmp="$SNAP.$$"
    printf '%s\n' "$limits" > "$tmp" && mv -f "$tmp" "$SNAP"
  fi
fi

if [ $# -gt 0 ] && [ -n "$1" ]; then
  # Hand the untouched input to the user's existing status line command.
  printf '%s' "$input" | bash -c "$1"
elif command -v jq >/dev/null 2>&1; then
  printf '%s' "$input" | jq -r '
    [.model.display_name // "Claude",
     (.rate_limits.five_hour.used_percentage // empty | "5h:\(floor)%"),
     (.rate_limits.seven_day.used_percentage // empty | "7d:\(floor)%")] | join(" | ")'
fi
