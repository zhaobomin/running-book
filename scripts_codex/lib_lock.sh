#!/usr/bin/env bash
set -euo pipefail

LOCK_MODE=""
LOCK_REF=""
LOCK_FD=""

lock_acquire() {
    local lock_file="$1"

    if command -v flock >/dev/null 2>&1; then
        exec {LOCK_FD}>"$lock_file"
        if ! flock -n "$LOCK_FD"; then
            return 1
        fi
        LOCK_MODE="flock"
        LOCK_REF="$lock_file"
        return 0
    fi

    local lock_dir="${lock_file}.dirlock"
    if mkdir "$lock_dir" 2>/dev/null; then
        echo "$$" > "${lock_dir}/pid"
        LOCK_MODE="mkdir"
        LOCK_REF="$lock_dir"
        return 0
    fi

    if [ -f "${lock_dir}/pid" ]; then
        local old_pid
        old_pid="$(cat "${lock_dir}/pid" 2>/dev/null || true)"
        if [ -n "$old_pid" ] && ! kill -0 "$old_pid" 2>/dev/null; then
            rm -rf "$lock_dir"
            if mkdir "$lock_dir" 2>/dev/null; then
                echo "$$" > "${lock_dir}/pid"
                LOCK_MODE="mkdir"
                LOCK_REF="$lock_dir"
                return 0
            fi
        fi
    fi

    return 1
}

lock_release() {
    if [ "$LOCK_MODE" = "flock" ] && [ -n "${LOCK_FD:-}" ]; then
        eval "exec ${LOCK_FD}>&-"
    elif [ "$LOCK_MODE" = "mkdir" ] && [ -n "${LOCK_REF:-}" ]; then
        rm -rf "$LOCK_REF"
    fi

    LOCK_MODE=""
    LOCK_REF=""
    LOCK_FD=""
}
