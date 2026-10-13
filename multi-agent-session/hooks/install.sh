#!/bin/sh
# Adds the Herdr pane-label hooks to ~/.claude/settings.json. Safe to run again.
set -eu
S="$HOME/.claude/settings.json"
H="$(cd "$(dirname "$0")" && pwd)/herdr-busy-label.sh"
chmod +x "$H"
mkdir -p "$(dirname "$S")"; [ -f "$S" ] || echo '{}' > "$S"
cp "$S" "$S.bak"
tmp=$(mktemp)
jq --arg h "sh '$H'" '
  def entry(a): {hooks: [{type: "command", command: ($h + " " + a), timeout: 5}]};
  def clean: map(select(any(.hooks[]?; .command | test("herdr-busy-label")) | not));
  .hooks //= {}
  | .hooks.UserPromptSubmit = ((.hooks.UserPromptSubmit // []) | clean) + [entry("busy")]
  | .hooks.Stop             = ((.hooks.Stop // []) | clean) + [entry("idle")]
  | .hooks.StopFailure      = ((.hooks.StopFailure // []) | clean) + [entry("idle")]
' "$S" > "$tmp" && mv "$tmp" "$S"
echo "Herdr label hooks installed in $S (backup: $S.bak). Restart Claude sessions to load them."
