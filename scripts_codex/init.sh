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
PROMPT_FILE=""

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
    echo "Usage: scripts_codex/init.sh [--new|--resume]"
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

if ! lock_acquire "$CODEX_INIT_LOCK_FILE"; then
    echo "==> another init run is active, skipping"
    exit 0
fi

if [ "$RUN_MODE" = "resume" ]; then
    RUN_ID="$(state_latest_resumable_run "INIT" || true)"
    if [ -z "$RUN_ID" ]; then
        RUN_MODE="new"
    fi
fi

if [ "$RUN_MODE" = "new" ]; then
    RUN_ID="init-$(new_run_id)"
    state_create_run "$RUN_ID" "new" "INIT"
else
    state_set_run_status "$RUN_ID" "RUNNING"
fi

PLAN="${CODEX_PLANS_DIR}/${RUN_ID}-plan.md"
LOG="${CODEX_LOGS_DIR}/${RUN_ID}.log"
PROMPT_FILE="${CODEX_LOGS_DIR}/${RUN_ID}-prompt.txt"
STREAM_LOG="${CODEX_LOGS_DIR}/${RUN_ID}-stream.jsonl"
SUMMARY_MD="${CODEX_REPORTS_DIR}/${RUN_ID}-summary.md"

if [ "$RUN_MODE" = "new" ]; then
    : > "$LOG"
    : > "$STREAM_LOG"
else
    [ -f "$LOG" ] || : > "$LOG"
    [ -f "$STREAM_LOG" ] || : > "$STREAM_LOG"
fi

state_record_artifact "$RUN_ID" "PLAN" "$PLAN"
state_record_artifact "$RUN_ID" "LOG" "$LOG"
state_record_artifact "$RUN_ID" "PROMPT_FILE" "$PROMPT_FILE"
state_record_artifact "$RUN_ID" "STREAM_LOG" "$STREAM_LOG"
state_record_artifact "$RUN_ID" "SUMMARY_MD" "$SUMMARY_MD"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

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

stage_generate() {
    log "${GREEN}==> [20_generate] build governance files${NC}"

    cat > "$CODEX_README_FILE" <<EOF_README
# 自动化写书（本地）
1) 把你的第一版书稿（md/docx/txt/pdf 等）放到 contents/
2) 如果你已有分章 Markdown，可放到 ${CODEX_DOCS_DIR}/
3) 运行：
   - ${CODEX_SCRIPTS_DIR}/init.sh          # 初始化（生成目录/风格/约束/评分与初始改进计划）
   - ${CODEX_SCRIPTS_DIR}/daily.sh         # 手动跑一轮每日迭代
   - ${CODEX_SCRIPTS_DIR}/install_cron.sh  # 安装每天定时跑
EOF_README

    cat > "$PROMPT_FILE" <<EOF_PROMPT
你是“跑步教练 + 出版编辑总监 + 严谨审校”。请在当前仓库完成《跑步训练与实践》一书的初始化治理，目标是让后续每天自动优化都能稳定推进。

请读取：
- contents/ 下所有文件（可能是第一版原稿、参考资料）
- ${CODEX_DOCS_DIR}/ 下所有 Markdown（如果有）

并生成/更新以下四个文件（直接写到仓库）：
1) ${CODEX_OUTLINE_FILE}：全书目录结构（章节标题、每章目标、关键点、读者收益）
2) ${CODEX_STYLE_GUIDE_FILE}：写作风格与统一口径（受众画像、语气、术语表、结构模板、示例标准）
3) ${CODEX_CONSTRAINTS_FILE}：硬约束（安全免责声明、医疗相关边界、引用/事实要求、不可编造规则）
4) ${CODEX_RUBRIC_FILE}：评分量表（每章从结构清晰度、可执行性、准确性、重复度、术语一致性、风险提示等维度打分，给出可检查的扣分标准）

另外，请生成一个初始化改进计划文件：${PLAN}，包含：
- Top 15 问题清单（按严重程度排序，引用章节/段落位置）
- 未来 7 天的改进路线图（每天最多改 2-3 章）
- 每天的验收标准（可检查）
- 风险与不确定性清单（需要作者确认的信息）

重要规则：
- 不要编造你没看到的事实或参考来源；缺信息就列“需确认”
- 涉及伤病/医疗必须加“非医疗建议”与“何时就医”的触发条件
- 只做“初始化治理+计划”，不要重写整本书
EOF_PROMPT

    run_codex "$(cat "$PROMPT_FILE")"
}

stage_finalize() {
    log "${GREEN}==> [30_finalize] write summary${NC}"
    cat > "$SUMMARY_MD" <<EOF_SUMMARY
# Init Summary

- Run ID: $RUN_ID
- Plan: $PLAN
- Prompt: $PROMPT_FILE
- Log: $LOG
- Stream: $STREAM_LOG
- Governance Files:
  - $CODEX_OUTLINE_FILE
  - $CODEX_STYLE_GUIDE_FILE
  - $CODEX_CONSTRAINTS_FILE
  - $CODEX_RUBRIC_FILE
EOF_SUMMARY

    log "${GREEN}==> Init done: run=$RUN_ID${NC}"
    log " - plan: $PLAN"
    log " - summary: $SUMMARY_MD"
    log " - log: $LOG"
    return 0
}

log "${GREEN}==> init mode: $RUN_MODE, run id: $RUN_ID${NC}"
state_set_run_status "$RUN_ID" "RUNNING"

if ! run_stage "$RUN_ID" "10_precheck" stage_precheck; then
    log "${RED}stage failed: 10_precheck${NC}"
    state_set_run_status "$RUN_ID" "FAILED"
    exit 1
fi

if ! run_stage "$RUN_ID" "20_generate" stage_generate; then
    log "${RED}stage failed: 20_generate${NC}"
    state_set_run_status "$RUN_ID" "FAILED"
    exit 1
fi

if ! run_stage "$RUN_ID" "30_finalize" stage_finalize; then
    log "${RED}stage failed: 30_finalize${NC}"
    state_set_run_status "$RUN_ID" "FAILED"
    exit 1
fi

state_set_run_status "$RUN_ID" "DONE"
