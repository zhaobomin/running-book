#!/bin/bash
# 持续优化调度脚本
# 定期执行任务生成和自动运行

PROJECT_DIR="/Users/zhaobomin/Documents/projects/running-book"
cd "$PROJECT_DIR"

LOG_FILE="tasks/scheduler.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

main() {
    log "=== 持续优化调度启动 ==="
    
    # 1. 生成新的优化任务
    log "步骤 1: 生成优化任务..."
    python3 tasks/generate-tasks.py
    
    # 2. 执行任务
    log "步骤 2: 开始执行任务..."
    python3 tasks/auto-run.py
    
    log "=== 持续优化调度完成 ==="
}

main "$@"
