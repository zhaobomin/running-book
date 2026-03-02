#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CRON_LINE="15 9 * * * cd $ROOT && bash scripts/daily.sh >> logs/cron.log 2>&1"

( crontab -l 2>/dev/null | grep -v "scripts/daily.sh" || true
  echo "$CRON_LINE"
) | crontab -

echo "已安装 cron：每天 09:15 运行 daily.sh"
echo "查看：crontab -l"