#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

source "$ROOT/scripts_codex/config.sh"
source "$ROOT/scripts_codex/lib_codex_stream.sh"
source "$ROOT/scripts_codex/lib_state.sh"
source "$ROOT/scripts_codex/lib_stage.sh"
source "$ROOT/scripts_codex/lib_lock.sh"

codex_ensure_runtime_dirs

RUN_ID=""
LOG=""

log() {
    local msg="$1"
    if [ -n "${LOG:-}" ]; then
        echo -e "$msg" | tee -a "$LOG"
    else
        echo -e "$msg"
    fi
}

on_interrupt() {
    log "\n==> interrupted, exiting..."
    if [ -n "${RUN_ID:-}" ] && command -v state_set_run_status >/dev/null 2>&1; then
        state_set_run_status "$RUN_ID" "FAILED" || true
    fi
    exit 130
}
trap on_interrupt INT TERM
trap 'lock_release' EXIT

usage() {
    echo "Usage: scripts_codex/daily.sh [--new|--resume]"
}

RUN_MODE="new"
if [ "$#" -gt 0 ]; then
    case "$1" in
        --new)
            RUN_MODE="new"
            ;;
        --resume)
            RUN_MODE="resume"
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
fi

if ! lock_acquire "$CODEX_LOCK_FILE"; then
    echo "==> another daily run is active, skipping"
    exit 0
fi

if [ "$RUN_MODE" = "resume" ]; then
    RUN_ID="$(state_latest_resumable_run "DAILY" || true)"
    if [ -z "$RUN_ID" ]; then
        RUN_MODE="new"
    fi
fi

if [ "$RUN_MODE" = "new" ]; then
    RUN_ID="$(new_run_id)"
    state_create_run "$RUN_ID" "new" "DAILY"
else
    state_set_run_status "$RUN_ID" "RUNNING"
fi

PLAN="${CODEX_PLANS_DIR}/${RUN_ID}-plan.md"
CHANGELOG="${CODEX_CHANGELOGS_DIR}/${RUN_ID}.md"
LOG="${CODEX_LOGS_DIR}/${RUN_ID}-daily.log"
STREAM_LOG="${CODEX_LOGS_DIR}/${RUN_ID}-daily-stream.jsonl"
CHECK_JSON="${CODEX_REPORTS_DIR}/${RUN_ID}-check.json"
SUMMARY_MD="${CODEX_REPORTS_DIR}/${RUN_ID}-summary.md"

if [ "$RUN_MODE" = "new" ]; then
    : > "$LOG"
    : > "$STREAM_LOG"
else
    [ -f "$LOG" ] || : > "$LOG"
    [ -f "$STREAM_LOG" ] || : > "$STREAM_LOG"
fi

state_record_artifact "$RUN_ID" "PLAN" "$PLAN"
state_record_artifact "$RUN_ID" "CHANGELOG" "$CHANGELOG"
state_record_artifact "$RUN_ID" "LOG" "$LOG"
state_record_artifact "$RUN_ID" "STREAM_LOG" "$STREAM_LOG"
state_record_artifact "$RUN_ID" "CHECK_JSON" "$CHECK_JSON"
state_record_artifact "$RUN_ID" "SUMMARY_MD" "$SUMMARY_MD"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Independent-run safeguard for governance docs.
[ -f "$CODEX_OUTLINE_FILE" ] || printf "# 书籍目录（待初始化生成）\n" > "$CODEX_OUTLINE_FILE"
[ -f "$CODEX_STYLE_GUIDE_FILE" ] || printf "# 写作风格指南（待初始化生成）\n" > "$CODEX_STYLE_GUIDE_FILE"
[ -f "$CODEX_CONSTRAINTS_FILE" ] || printf "# 硬约束（待初始化生成）\n" > "$CODEX_CONSTRAINTS_FILE"
[ -f "$CODEX_RUBRIC_FILE" ] || printf "# 评分量表（待初始化生成）\n" > "$CODEX_RUBRIC_FILE"

run_codex() {
    local prompt="$1"
    run_codex_stream "$prompt" "$LOG" "$STREAM_LOG"
}

stage_precheck() {
    command -v codex >/dev/null
    command -v python3 >/dev/null
    codex --version >>"$LOG" 2>&1
    return 0
}

stage_plan() {
    log "${GREEN}==> [20_plan] generate daily plan${NC}"
    run_codex "
你是跑步教练+编辑总监。请读取：
- ${CODEX_OUTLINE_FILE}, ${CODEX_STYLE_GUIDE_FILE}, ${CODEX_CONSTRAINTS_FILE}, ${CODEX_RUBRIC_FILE}
- ${CODEX_DOCS_DIR}/ 下全部章节
- 最近 7 天 ${CODEX_CHANGELOGS_DIR}/（如果存在）

任务A：输出今日改进计划到 ${PLAN}，要求：
1) 选 2-3 章作为今日改动目标（不要贪多）
2) 每章列：问题诊断（引用段落）、改动策略、验收标准（rubric 对齐）
3) 风险/需确认点（不要编）

只输出计划，不要改文件。
"
}

stage_edit() {
    log "${GREEN}==> [30_edit] apply changes${NC}"
    run_codex "
读取 ${PLAN}，并严格按计划执行：
- 只改计划中指定的章节文件（${CODEX_DOCS_DIR}/ 内）
- 每章末尾追加\"本次修改摘要（3-5条）\"
- 输出变更记录到 ${CHANGELOG}（改了什么、为什么、对 rubric 哪项提升、还有哪些待确认）

限制：
- 不要引入未经证实的数据或研究结论；需要引用就写\"建议后续补参考\"
- 医疗/伤病必须包含边界与就医触发条件
"
}

stage_review() {
    log "${GREEN}==> [40_review] re-score chapters${NC}"
    run_codex "
请根据 ${CODEX_RUBRIC_FILE} 对今天被修改的章节重新打分（0-5分），并把结果追加到 ${CHANGELOG} 末尾：
- 每章：各维度分数 + 1段证据说明 + 下一步建议（最多5条）
"
}

stage_check() {
    log "${GREEN}==> [50_check] run checks${NC}"
    if [ ! -f "${CODEX_SCRIPTS_DIR}/check.sh" ]; then
        cat > "$CHECK_JSON" <<JSON
{"status":"SKIP","reason":"missing check.sh"}
JSON
        return 0
    fi

    bash "${CODEX_SCRIPTS_DIR}/check.sh" "$CHECK_JSON" 2>&1 | tee -a "$LOG"
    return ${PIPESTATUS[0]}
}

stage_finalize() {
    log "${GREEN}==> [60_finalize] summary${NC}"
    if [ -f "${CODEX_SCRIPTS_DIR}/report.sh" ]; then
        bash "${CODEX_SCRIPTS_DIR}/report.sh" "$RUN_ID" "$PLAN" "$CHANGELOG" "$LOG" "$CHECK_JSON" "$SUMMARY_MD" 2>&1 | tee -a "$LOG"
    fi

    log "${YELLOW}==> git operations disabled (no add/commit)${NC}"
    log "${GREEN}==> Done: run=$RUN_ID${NC}"
    log " - plan: $PLAN"
    log " - changelog: $CHANGELOG"
    log " - check: $CHECK_JSON"
    log " - summary: $SUMMARY_MD"
    log " - log: $LOG"
    return 0
}

log "${GREEN}==> run mode: $RUN_MODE, run id: $RUN_ID${NC}"
state_set_run_status "$RUN_ID" "RUNNING"

if ! run_stage "$RUN_ID" "10_precheck" stage_precheck; then
    log "${RED}stage failed: 10_precheck${NC}"
    state_set_run_status "$RUN_ID" "FAILED"
    exit 1
fi

if ! run_stage "$RUN_ID" "20_plan" stage_plan; then
    log "${RED}stage failed: 20_plan${NC}"
    state_set_run_status "$RUN_ID" "FAILED"
    exit 1
fi

if ! run_stage "$RUN_ID" "30_edit" stage_edit; then
    log "${RED}stage failed: 30_edit${NC}"
    state_set_run_status "$RUN_ID" "FAILED"
    exit 1
fi

if ! run_stage "$RUN_ID" "40_review" stage_review; then
    log "${RED}stage failed: 40_review${NC}"
    state_set_run_status "$RUN_ID" "FAILED"
    exit 1
fi

run_stage_soft "$RUN_ID" "50_check" stage_check
if ! run_stage "$RUN_ID" "60_finalize" stage_finalize; then
    log "${RED}stage failed: 60_finalize${NC}"
    state_set_run_status "$RUN_ID" "FAILED"
    exit 1
fi

state_set_run_status "$RUN_ID" "DONE"
