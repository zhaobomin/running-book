#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "$ROOT/scripts_codex/config.sh"
source "$ROOT/scripts_codex/lib_state.sh"

RUN_ID="$1"
PLAN="$2"
CHANGELOG="$3"
LOG_FILE="$4"
CHECK_JSON="$5"
SUMMARY_MD="$6"

run_dir="$(state_run_dir "$RUN_ID")"

stage_status() {
    local stage="$1"
    stage_get_status "$RUN_ID" "$stage"
}

check_status="UNKNOWN"
if [ -f "$CHECK_JSON" ]; then
    check_status="$(python3 - "$CHECK_JSON" <<'PY'
import json
import sys
path = sys.argv[1]
try:
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    print(data.get('status', 'UNKNOWN'))
except Exception:
    print('UNKNOWN')
PY
)"
fi

run_status="$(state_get_env "$(state_run_env "$RUN_ID")" "RUN_STATUS" 2>/dev/null || echo "UNKNOWN")"

cat > "$SUMMARY_MD" <<EOF_MD
# Daily Summary

- Run ID: $RUN_ID
- Run Status: $run_status
- Check Status: $check_status
- Plan: $PLAN
- Changelog: $CHANGELOG
- Log: $LOG_FILE

## Stage Status

- 10_precheck: $(stage_status "10_precheck")
- 20_plan: $(stage_status "20_plan")
- 30_edit: $(stage_status "30_edit")
- 40_review: $(stage_status "40_review")
- 50_check: $(stage_status "50_check")
- 60_finalize: $(stage_status "60_finalize")

## State Dir

- $run_dir
EOF_MD

if [ "$check_status" = "FAIL" ]; then
    echo "[report] check failed (soft fail), pipeline continued" >&2
fi
