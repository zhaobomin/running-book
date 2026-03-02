#!/usr/bin/env bash

# 捕获 Ctrl+C 信号，确保能正常退出
trap 'echo -e "\n==> 用户中断，退出..."; kill $(jobs -p) 2>/dev/null; exit 130' INT TERM

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p plans changelogs logs

DATE="$(date +%F)"
PLAN="plans/${DATE}-plan.md"
CHANGELOG="changelogs/${DATE}.md"
LOG="logs/${DATE}-daily.log"
STREAM_LOG="logs/${DATE}-stream.jsonl"

# 清空日志文件
: > "$LOG"
: > "$STREAM_LOG"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "$1" | tee -a "$LOG"
}

# 解析 stream-json 输出的函数（使用单一 Python 进程，减少延迟）
parse_stream_json() {
    python3 -u -c '
import sys
import json

stream_log = open(sys.argv[1], "a")

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    # 保存原始 JSON
    stream_log.write(line + "\n")
    stream_log.flush()
    # 解析并输出
    try:
        data = json.loads(line)
        if data.get("type") == "text" and "text" in data:
            sys.stdout.write(data["text"])
            sys.stdout.flush()
    except:
        pass
' "$STREAM_LOG"
}

run_claude() {
    local prompt="$1"
    # 使用 stream-json 实现真正的流式输出
    # --permission-mode bypassPermissions 跳过所有权限检查（适用于信任的本地仓库）
    claude --verbose -p "$prompt" --output-format stream-json --permission-mode bypassPermissions 2>>"$LOG" | parse_stream_json | tee -a "$LOG"
    return ${PIPESTATUS[0]}
}

log "${GREEN}==> Day $DATE: 生成今日计划${NC}"
run_claude "
你是跑步教练+编辑总监。请读取：
- outline.md, style_guide.md, constraints.md, rubric.md
- docs/ 下全部章节
- 最近 7 天 changelogs/（如果存在）

任务A：输出今日改进计划到 $PLAN，要求：
1) 选 2-3 章作为今日改动目标（不要贪多）
2) 每章列：问题诊断（引用段落）、改动策略、验收标准（rubric 对齐）
3) 风险/需确认点（不要编）

只输出计划，不要改文件。
"

log "${GREEN}==> 执行改写${NC}"
run_claude "
读取 $PLAN，并严格按计划执行：
- 只改计划中指定的章节文件（book/ 内）
- 每章末尾追加"本次修改摘要（3-5条）"
- 输出变更记录到 $CHANGELOG（改了什么、为什么、对 rubric 哪项提升、还有哪些待确认）

限制：
- 不要引入未经证实的数据或研究结论；需要引用就写"建议后续补参考"
- 医疗/伤病必须包含边界与就医触发条件
"

log "${GREEN}==> 回归评审（改完再打分一次）${NC}"
run_claude "
请根据 rubric.md 对今天被修改的章节重新打分（0-5分），并把结果追加到 $CHANGELOG 末尾：
- 每章：各维度分数 + 1段证据说明 + 下一步建议（最多5条）
"

log "${GREEN}==> 基础检查${NC}"
if [ -f "scripts/check.sh" ]; then
    bash scripts/check.sh 2>&1 | tee -a "$LOG" || true
fi

log "${GREEN}==> 自动提交（可选）${NC}"
if [ -d .git ]; then
    git add docs/ "$PLAN" "$CHANGELOG" outline.md style_guide.md constraints.md rubric.md 2>/dev/null || true
    git commit -m "daily: improve running book ${DATE}" 2>/dev/null || log "${YELLOW}警告：无变更需要提交${NC}"
fi

log "${GREEN}==> Done: $PLAN / $CHANGELOG / $LOG${NC}"