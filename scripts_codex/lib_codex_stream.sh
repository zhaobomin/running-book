#!/usr/bin/env bash
set -euo pipefail

run_codex_stream() {
    local prompt="$1"
    local log_file="$2"
    local stream_log="$3"
    local max_attempts="${4:-3}"
    local attempt=1
    local rc=0

    while [ "$attempt" -le "$max_attempts" ]; do
        codex exec --full-auto --sandbox workspace-write --json "$prompt" 2>>"$log_file" | \
            python3 -u -c '
import json
import sys

stream_log = open(sys.argv[1], "a", encoding="utf-8")
has_output = False

for raw in sys.stdin:
    line = raw.rstrip("\n")
    if not line:
        continue

    stream_log.write(line + "\n")
    stream_log.flush()

    try:
        data = json.loads(line)
    except Exception:
        continue

    event_type = data.get("type", "")
    chunk = None

    if event_type in ("response.output_text.delta", "output_text.delta", "agent_message_delta"):
        chunk = data.get("delta")
    elif event_type == "text":
        chunk = data.get("text")

    if isinstance(chunk, str) and chunk:
        sys.stdout.write(chunk)
        sys.stdout.flush()
        has_output = True
        continue

    if event_type == "error":
        msg = data.get("message")
        if isinstance(msg, str) and msg:
            if has_output:
                sys.stdout.write("\n")
            sys.stdout.write(f"[codex] {msg}\n")
            sys.stdout.flush()
            has_output = False

if has_output:
    sys.stdout.write("\n")
    sys.stdout.flush()
' "$stream_log" | tee -a "$log_file"
        rc=${PIPESTATUS[0]}
        if [ "$rc" -eq 0 ]; then
            return 0
        fi
        if [ "$attempt" -lt "$max_attempts" ]; then
            echo "[codex] command failed (attempt ${attempt}/${max_attempts}), retrying..." | tee -a "$log_file"
            sleep $((attempt * 2))
        fi
        attempt=$((attempt + 1))
    done

    return "$rc"
}
