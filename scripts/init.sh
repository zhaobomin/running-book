#!/usr/bin/env bash

# 捕获 Ctrl+C 信号，确保能正常退出
trap 'echo -e "\n==> 用户中断，退出..."; kill $(jobs -p) 2>/dev/null; exit 130' INT TERM

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

mkdir -p docs sources plans changelogs logs scripts

# 初始化占位文件（若不存在）
[ -f outline.md ]      || printf "# 书籍目录（待初始化生成）\n" > outline.md
[ -f style_guide.md ]  || printf "# 写作风格指南（待初始化生成）\n" > style_guide.md
[ -f constraints.md ]  || printf "# 硬约束（待初始化生成）\n" > constraints.md
[ -f rubric.md ]       || printf "# 评分量表（待初始化生成）\n" > rubric.md

cat > README_AUTORUN.md <<'EOF'
# 自动化写书（本地）
1) 把你的第一版书稿（md/docx/txt/pdf 等）放到 contents/
2) 如果你已有分章 Markdown，可放到 docs/
3) 运行：
   - scripts/init.sh          # 初始化（生成目录/风格/约束/评分与初始改进计划）
   - scripts/daily.sh         # 手动跑一轮每日迭代
   - scripts/install_cron.sh  # 安装每天定时跑
EOF

DATE="$(date +%F)"
PLAN="plans/${DATE}-init-plan.md"
LOG="logs/${DATE}-init.log"
PROMPT_FILE="logs/${DATE}-init-prompt.txt"
STREAM_LOG="logs/${DATE}-init-stream.jsonl"

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

log "${GREEN}==> 初始化：生成 outline/style/constraints/rubric + 初始计划${NC}"
log "${GREEN}==> 你应该先把第一版书稿放到 contents/ 或把分章稿放到 docs/${NC}"

# 把初始化 Prompt 写入文件（避免 heredoc/变量嵌套导致 bash 误解析）
cat > "$PROMPT_FILE" <<EOF
你是“跑步教练 + 出版编辑总监 + 严谨审校”。请在当前仓库完成《跑步训练与实践》一书的初始化治理，目标是让后续每天自动优化都能稳定推进。

请读取：
- contents/ 下所有文件（可能是第一版原稿、参考资料）
- docs/ 下所有 Markdown（如果有）

并生成/更新以下四个文件（直接写到仓库）：
1) outline.md：全书目录结构（章节标题、每章目标、关键点、读者收益）
2) style_guide.md：写作风格与统一口径（受众画像、语气、术语表、结构模板、示例标准）
3) constraints.md：硬约束（安全免责声明、医疗相关边界、引用/事实要求、不可编造规则）
4) rubric.md：评分量表（每章从结构清晰度、可执行性、准确性、重复度、术语一致性、风险提示等维度打分，给出可检查的扣分标准）

另外，请生成一个初始化改进计划文件：$PLAN，包含：
- Top 15 问题清单（按严重程度排序，引用章节/段落位置）
- 未来 7 天的改进路线图（每天最多改 2-3 章）
- 每天的验收标准（可检查）
- 风险与不确定性清单（需要作者确认的信息）

重要规则：
- 不要编造你没看到的事实或参考来源；缺信息就列“需确认”
- 涉及伤病/医疗必须加“非医疗建议”与“何时就医”的触发条件
- 只做“初始化治理+计划”，不要重写整本书
EOF

# 执行（把 prompt 文件内容传给 claude）
run_claude "$(cat "$PROMPT_FILE")"

log "${GREEN}==> 初始化完成：${NC}"
log " - outline.md / style_guide.md / constraints.md / rubric.md"
log " - $PLAN"
log " - 日志：$LOG"
log " - Prompt：$PROMPT_FILE"

log "${GREEN}==> 下一步：打开 $PLAN 看 7 天游标；然后跑 scripts/daily.sh 执行第 1 天游标。${NC}"