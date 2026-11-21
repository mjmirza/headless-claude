#!/usr/bin/env bash
# Checks that documented --output-format json paths match the CLI result.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
fixture="$root/tests/fixtures/print-json-result.json"
example=$(awk '
  /Example JSON structure/ { in_section = 1 }
  in_section && /^```json$/ { capture = 1; next }
  capture && /^```$/ { exit }
  capture { print }
' "$root/examples/01-basic/README.md")

diff -u <(jq -S . <<<"$example") <(jq -S . "$fixture") >/dev/null

session_id=$(jq -r '.session_id' "$fixture")
cost=$(jq -r '.total_cost_usd' "$fixture")
duration=$(jq -r '.duration_ms' "$fixture")
turns=$(jq -r '.num_turns' "$fixture")
result=$(jq -r '.result' "$fixture")

[ "$session_id" = "550e8400-e29b-41d4-a716-446655440000" ]
[ "$cost" = "0.0123" ]
[ "$duration" = "4500" ]
[ "$turns" = "3" ]
[ "$result" = "Here are the TypeScript files..." ]

# The fields this guide used to document are not on the result object.
[ -z "$(jq -r '.metadata.sessionId // empty' "$fixture")" ]
[ -z "$(jq -r '.metadata.totalCost // empty' "$fixture")" ]
[ -z "$(jq -r '.metadata.duration // empty' "$fixture")" ]
[ -z "$(jq -r '.metadata.turns // empty' "$fixture")" ]

# Summing cost and duration across hosts reads the same top-level fields.
totals=$(jq -s '{total_cost_usd: map(.total_cost_usd) | add, duration_ms: map(.duration_ms) | add}' "$fixture" "$fixture")
[ "$(jq -r '.total_cost_usd' <<<"$totals")" = "0.0246" ]
[ "$(jq -r '.duration_ms' <<<"$totals")" = "9000" ]

stale=0
while IFS= read -r file; do
  if grep -nE '\.metadata\.(sessionId|totalCost|duration|turns)|~/?\.claude/transcripts|\.claude/transcripts' "$file"; then
    echo "stale session path in $file" >&2
    stale=1
  fi
done < <(find "$root" -path "$root/.git" -prune -o -name '*.md' ! -name 'CHANGELOG.md' -print)

session_flags=$(grep -RInE --exclude-dir=.git --include='*.md' -e '--session-id[[:space:]]+"[^"]+"' "$root" || true)
if [ -n "$session_flags" ]; then
  if printf '%s\n' "$session_flags" \
    | grep -vE -- '--session-id[[:space:]]+"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"'; then
    echo "non-UUID --session-id remains" >&2
    stale=1
  fi
fi

[ "$stale" -eq 0 ]
echo "JSON result fields match the documented paths."
