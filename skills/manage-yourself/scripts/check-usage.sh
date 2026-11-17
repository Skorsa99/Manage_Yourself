#!/usr/bin/env bash
# Prints the user's plan and current 5-hour / 7-day usage for the
# manage-yourself skill. Reads the snapshot written by usage-snapshot.sh.
#
# Usage: check-usage.sh          human-readable summary
#        check-usage.sh --json   machine-readable JSON

set -u
SNAP="${MANAGE_YOURSELF_DIR:-$HOME/.claude/manage-yourself}/usage-snapshot.json"
STALE_AFTER=600   # seconds

command -v jq >/dev/null 2>&1 || { echo "error: jq is required (brew install jq)" >&2; exit 2; }

plan=$(claude auth status --json 2>/dev/null | jq -r '.subscriptionType // empty' 2>/dev/null)
[ -n "$plan" ] || plan="unknown"
now=$(date +%s)

if [ -f "$SNAP" ]; then
  json=$(jq --arg plan "$plan" --argjson now "$now" --argjson stale "$STALE_AFTER" '
    def win(w):
      if w == null then {status: "no_data"}
      elif (w.resets_at // 0) <= $now then {status: "reset", used_percentage: 0, remaining_percentage: 100}
      else {status: "ok",
            used_percentage: w.used_percentage,
            remaining_percentage: (100 - w.used_percentage),
            resets_at: w.resets_at,
            resets_at_local: (w.resets_at | strflocaltime("%a %Y-%m-%d %H:%M")),
            resets_in_minutes: (((w.resets_at - $now) / 60) | floor)}
      end;
    {plan: $plan,
     snapshot: (if ($now - .captured_at) > $stale then "stale" else "fresh" end),
     snapshot_age_seconds: ($now - .captured_at),
     five_hour: win(.rate_limits.five_hour),
     seven_day: win(.rate_limits.seven_day)}' "$SNAP")
else
  json=$(jq -n --arg plan "$plan" '{plan: $plan, snapshot: "missing"}')
fi

if [ "${1:-}" = "--json" ]; then
  printf '%s\n' "$json"
  exit 0
fi

printf '%s\n' "$json" | jq -r '
  def line(name; w):
    if w.status == "ok" then
      "\(name): \(w.used_percentage)% used, \(w.remaining_percentage)% left, resets \(w.resets_at_local) (in \(w.resets_in_minutes) min)"
    elif w.status == "reset" then "\(name): window has reset since the snapshot, treat as 0% used"
    else "\(name): no data" end;
  "plan: \(.plan)",
  if .snapshot == "missing" then
    "usage: no snapshot found. Set up usage-snapshot.sh as the status line (see the skill README)."
  else
    line("5-hour"; .five_hour),
    line("7-day"; .seven_day),
    "snapshot: \(.snapshot) (\(.snapshot_age_seconds)s old)"
  end'
