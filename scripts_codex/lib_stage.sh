#!/usr/bin/env bash
set -euo pipefail

run_stage() {
    local run_id="$1"
    local stage="$2"
    local fn="$3"

    local current_status
    current_status="$(stage_get_status "$run_id" "$stage")"
    if [ "$current_status" = "DONE" ]; then
        log "[stage:${stage}] already DONE, skipping"
        return 0
    fi

    if [ "$current_status" = "RUNNING" ]; then
        log "[stage:${stage}] found stale RUNNING, restarting stage"
    fi

    stage_set_status "$run_id" "$stage" "RUNNING"
    if "$fn"; then
        stage_set_status "$run_id" "$stage" "DONE"
        return 0
    fi

    stage_set_status "$run_id" "$stage" "FAILED"
    return 1
}

run_stage_soft() {
    local run_id="$1"
    local stage="$2"
    local fn="$3"

    local current_status
    current_status="$(stage_get_status "$run_id" "$stage")"
    if [ "$current_status" = "DONE" ] || [ "$current_status" = "SOFT_FAIL" ]; then
        log "[stage:${stage}] already ${current_status}, skipping"
        return 0
    fi

    if [ "$current_status" = "RUNNING" ]; then
        log "[stage:${stage}] found stale RUNNING, restarting stage"
    fi

    stage_set_status "$run_id" "$stage" "RUNNING"
    if "$fn"; then
        stage_set_status "$run_id" "$stage" "DONE"
    else
        stage_set_status "$run_id" "$stage" "SOFT_FAIL"
    fi
    return 0
}
