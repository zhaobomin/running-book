#!/usr/bin/env bash
set -euo pipefail

state_run_dir() {
    local run_id="$1"
    echo "${CODEX_STATE_DIR}/runs/${run_id}"
}

state_run_env() {
    local run_id="$1"
    echo "$(state_run_dir "$run_id")/run.env"
}

state_stages_dir() {
    local run_id="$1"
    echo "$(state_run_dir "$run_id")/stages"
}

state_stage_status_file() {
    local run_id="$1"
    local stage="$2"
    echo "$(state_stages_dir "$run_id")/${stage}.status"
}

state_artifacts_file() {
    local run_id="$1"
    echo "$(state_run_dir "$run_id")/artifacts.env"
}

new_run_id() {
    date +%Y-%m-%dT%H%M%S
}

state_set_env() {
    local env_file="$1"
    local key="$2"
    local value="$3"
    if [ -f "$env_file" ] && grep -q "^${key}=" "$env_file"; then
        sed -i.bak "s|^${key}=.*|${key}=${value}|" "$env_file"
        rm -f "${env_file}.bak"
    else
        echo "${key}=${value}" >> "$env_file"
    fi
}

state_get_env() {
    local env_file="$1"
    local key="$2"
    if [ ! -f "$env_file" ]; then
        return 1
    fi
    awk -F= -v k="$key" '$1 == k { print substr($0, index($0, "=") + 1); found=1 } END { if (!found) exit 1 }' "$env_file"
}

state_create_run() {
    local run_id="$1"
    local run_mode="$2"
    local run_kind="${3:-DAILY}"
    local run_dir
    run_dir="$(state_run_dir "$run_id")"
    mkdir -p "$run_dir" "$(state_stages_dir "$run_id")"
    : > "$(state_artifacts_file "$run_id")"

    local env_file
    env_file="$(state_run_env "$run_id")"
    : > "$env_file"
    state_set_env "$env_file" "RUN_ID" "$run_id"
    state_set_env "$env_file" "RUN_MODE" "$run_mode"
    state_set_env "$env_file" "RUN_KIND" "$run_kind"
    state_set_env "$env_file" "RUN_STATUS" "RUNNING"
    state_set_env "$env_file" "STARTED_AT" "$(date +%FT%T%z)"
    state_set_env "$env_file" "UPDATED_AT" "$(date +%FT%T%z)"
}

state_touch_run() {
    local run_id="$1"
    local env_file
    env_file="$(state_run_env "$run_id")"
    state_set_env "$env_file" "UPDATED_AT" "$(date +%FT%T%z)"
}

state_record_artifact() {
    local run_id="$1"
    local key="$2"
    local value="$3"
    state_set_env "$(state_artifacts_file "$run_id")" "$key" "$value"
}

stage_get_status() {
    local run_id="$1"
    local stage="$2"
    local status_file
    status_file="$(state_stage_status_file "$run_id" "$stage")"
    if [ ! -f "$status_file" ]; then
        echo "PENDING"
        return 0
    fi
    cat "$status_file"
}

stage_set_status() {
    local run_id="$1"
    local stage="$2"
    local status="$3"
    local status_file
    status_file="$(state_stage_status_file "$run_id" "$stage")"
    echo "$status" > "$status_file"
    local env_file
    env_file="$(state_run_env "$run_id")"
    state_set_env "$env_file" "LAST_STAGE" "$stage"
    state_set_env "$env_file" "LAST_STAGE_STATUS" "$status"
    state_touch_run "$run_id"
}

state_set_run_status() {
    local run_id="$1"
    local run_status="$2"
    local env_file
    env_file="$(state_run_env "$run_id")"
    state_set_env "$env_file" "RUN_STATUS" "$run_status"
    if [ "$run_status" = "DONE" ] || [ "$run_status" = "FAILED" ]; then
        state_set_env "$env_file" "FINISHED_AT" "$(date +%FT%T%z)"
    fi
    state_touch_run "$run_id"
}

state_latest_resumable_run() {
    local run_kind_filter="${1:-}"
    local candidates
    candidates="$(find "${CODEX_STATE_DIR}/runs" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | sort -r || true)"
    if [ -z "$candidates" ]; then
        return 1
    fi

    local dir run_id env_file run_status run_kind
    while IFS= read -r dir; do
        [ -n "$dir" ] || continue
        run_id="$(basename "$dir")"
        env_file="$(state_run_env "$run_id")"
        run_status="$(state_get_env "$env_file" "RUN_STATUS" 2>/dev/null || true)"
        run_kind="$(state_get_env "$env_file" "RUN_KIND" 2>/dev/null || true)"
        if [ -n "$run_kind_filter" ] && [ "$run_kind" != "$run_kind_filter" ]; then
            continue
        fi
        if [ "$run_status" != "DONE" ]; then
            echo "$run_id"
            return 0
        fi
    done <<< "$candidates"

    return 1
}
