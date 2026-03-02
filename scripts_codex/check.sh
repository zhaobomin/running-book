#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "$ROOT/scripts_codex/config.sh"

OUT_JSON="${1:-}"

collect_matches() {
    local pattern="$1"
    find "$CODEX_DOCS_DIR" -type f -name '*.md' -not -path '*/.vitepress/*' -exec grep -nE "$pattern" {} + 2>/dev/null || true
}

echo "[check] empty headings"
empty_matches="$(collect_matches '^#\s*$')"
printf '%s\n' "$empty_matches"


echo "[check] leftover TODO"
todo_matches="$(collect_matches 'TODO')"
printf '%s\n' "$todo_matches"

echo "[check] repeated disclaimer count (rough)"
disclaimer_matches="$(collect_matches '非医疗建议')"
disclaimer_count="$(printf '%s\n' "$disclaimer_matches" | sed '/^$/d' | wc -l | tr -d ' ')"
echo "$disclaimer_count"

empty_count="$(printf '%s\n' "$empty_matches" | sed '/^$/d' | wc -l | tr -d ' ')"
todo_count="$(printf '%s\n' "$todo_matches" | sed '/^$/d' | wc -l | tr -d ' ')"

status="PASS"
if [ "$empty_count" -gt 0 ] || [ "$todo_count" -gt 0 ]; then
    status="FAIL"
fi

if [ -n "$OUT_JSON" ]; then
    cat > "$OUT_JSON" <<JSON
{
  "status": "$status",
  "empty_heading_count": $empty_count,
  "todo_count": $todo_count,
  "disclaimer_count": $disclaimer_count
}
JSON
fi

if [ "$status" = "FAIL" ]; then
    exit 1
fi

exit 0
