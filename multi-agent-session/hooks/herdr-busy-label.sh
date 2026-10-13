#!/bin/sh
# Herdr pane label for a Claude agent:
#   🔴 BUSY  - a turn runs (UserPromptSubmit)
#   🟡 BG n  - turn ended, n background tasks (shells, subagents, monitors) still run
#   (none)   - idle
# Claude starts a new turn when a background task ends, so Stop runs again and the label updates.
# ponytail: overwrites any manual pane name; read+restore the old label if you start naming panes by hand.
input=$(cat)
[ "${HERDR_ENV:-}" = 1 ] && [ -n "${HERDR_PANE_ID:-}" ] || exit 0
case "${1:-}" in
  busy) herdr pane rename "$HERDR_PANE_ID" "🔴 BUSY" ;;
  idle)
    n=$(printf '%s' "$input" | jq '[.background_tasks[]? | select(.status == "running")] | length' 2>/dev/null)
    if [ "${n:-0}" -gt 0 ]; then herdr pane rename "$HERDR_PANE_ID" "🟡 BG $n"
    else herdr pane rename "$HERDR_PANE_ID" --clear; fi ;;
esac >/dev/null 2>&1
exit 0
