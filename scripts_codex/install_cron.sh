#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source "$ROOT/scripts_codex/config.sh"
codex_ensure_runtime_dirs

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认时间 09:15，可通过参数自定义
TIME="${1:-15 9}"
CRON_LINE="$TIME * * * cd $ROOT && bash ${CODEX_SCRIPTS_DIR}/daily.sh --resume >> ${CODEX_LOGS_DIR}/cron.log 2>&1"

# 安装 cron
( crontab -l 2>/dev/null | grep -v "${CODEX_SCRIPTS_DIR}/daily.sh" || true
  echo "$CRON_LINE"
) | crontab -

echo -e "${GREEN}已安装 cron：每天 $TIME 运行 ${CODEX_SCRIPTS_DIR}/daily.sh --resume${NC}"
echo -e "${YELLOW}查看：crontab -l${NC}"
echo -e "${YELLOW}日志：${CODEX_LOGS_DIR}/cron.log${NC}"
