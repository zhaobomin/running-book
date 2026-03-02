#!/usr/bin/env bash
set -euo pipefail

CODEX_DOCS_DIR="${CODEX_DOCS_DIR:-docs}"
CODEX_SOURCES_DIR="${CODEX_SOURCES_DIR:-sources}"
CODEX_SCRIPTS_DIR="${CODEX_SCRIPTS_DIR:-scripts_codex}"
CODEX_PLANS_DIR="${CODEX_PLANS_DIR:-plans_codex}"
CODEX_CHANGELOGS_DIR="${CODEX_CHANGELOGS_DIR:-changelogs_codex}"
CODEX_LOGS_DIR="${CODEX_LOGS_DIR:-logs_codex}"
CODEX_STATE_DIR="${CODEX_STATE_DIR:-state_codex}"
CODEX_REPORTS_DIR="${CODEX_REPORTS_DIR:-reports_codex}"
CODEX_LOCK_FILE="${CODEX_LOCK_FILE:-state_codex/daily.lock}"
CODEX_INIT_LOCK_FILE="${CODEX_INIT_LOCK_FILE:-state_codex/init.lock}"
CODEX_README_FILE="${CODEX_README_FILE:-README_AUTORUN_CODEX.md}"
CODEX_OUTLINE_FILE="${CODEX_OUTLINE_FILE:-outline.md}"
CODEX_STYLE_GUIDE_FILE="${CODEX_STYLE_GUIDE_FILE:-style_guide.md}"
CODEX_CONSTRAINTS_FILE="${CODEX_CONSTRAINTS_FILE:-constraints.md}"
CODEX_RUBRIC_FILE="${CODEX_RUBRIC_FILE:-rubric.md}"

codex_ensure_base_dirs() {
    mkdir -p \
        "$CODEX_DOCS_DIR" \
        "$CODEX_SOURCES_DIR" \
        "$CODEX_SCRIPTS_DIR" \
        "$CODEX_PLANS_DIR" \
        "$CODEX_CHANGELOGS_DIR" \
        "$CODEX_LOGS_DIR" \
        "$CODEX_STATE_DIR" \
        "$CODEX_REPORTS_DIR"
}

codex_ensure_runtime_dirs() {
    codex_ensure_base_dirs
    mkdir -p "$CODEX_STATE_DIR/runs"
}
