#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p plans changelogs logs

DATE="$(date +%F)"
PLAN="plans/${DATE}-plan.md"
CHANGELOG="changelogs/${DATE}.md"
LOG="logs/${DATE}-daily.log"

echo "==> Day $DATE: 生成今日计划"
claude -p "
你是跑步教练+编辑总监。请读取：
- outline.md, style_guide.md, constraints.md, rubric.md
- docs/ 下全部章节
- 最近 7 天 changelogs/（如果存在）

任务A：输出今日改进计划到 $PLAN，要求：
1) 选 2-3 章作为今日改动目标（不要贪多）
2) 每章列：问题诊断（引用段落）、改动策略、验收标准（rubric 对齐）
3) 风险/需确认点（不要编）

只输出计划，不要改文件。
" > "$LOG"

echo "==> 执行改写"
claude -p "
读取 $PLAN，并严格按计划执行：
- 只改计划中指定的章节文件（book/ 内）
- 每章末尾追加“本次修改摘要（3-5条）”
- 输出变更记录到 $CHANGELOG（改了什么、为什么、对 rubric 哪项提升、还有哪些待确认）

限制：
- 不要引入未经证实的数据或研究结论；需要引用就写“建议后续补参考”
- 医疗/伤病必须包含边界与就医触发条件
" >> "$LOG"

echo "==> 回归评审（改完再打分一次）"
claude -p "
请根据 rubric.md 对今天被修改的章节重新打分（0-5分），并把结果追加到 $CHANGELOG 末尾：
- 每章：各维度分数 + 1段证据说明 + 下一步建议（最多5条）
" >> "$LOG"

echo "==> 基础检查"
bash scripts/checks.sh | tee -a "$LOG" || true

echo "==> 自动提交（可选）"
if [ -d .git ]; then
  git add book/ "$PLAN" "$CHANGELOG" outline.md style_guide.md constraints.md rubric.md || true
  git commit -m "daily: improve running book ${DATE}" || true
fi

echo "==> Done: $PLAN / $CHANGELOG / $LOG"