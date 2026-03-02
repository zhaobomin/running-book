#!/bin/bash

TASKS_FILE="tasks/tasks.json"
LOG_FILE="tasks/execution.log"

mkdir -p tasks

init_tasks() {
    if [ ! -f "$TASKS_FILE" ]; then
        echo "[]" > "$TASKS_FILE"
    fi
}

extract_tasks() {
    local output="$1"
    
    # 提取所有可能的任务格式
    echo "$output" | grep -E '^(\s*[-*]\s+|\s*\d+[.)]\s+|\s*\[ \]\s+|\s*任务\s*\d*[:：]?\s*|\s*子任务\s*[:：]?\s*)' | \
        sed 's/^\s*[-*]\s*//' | \
        sed 's/^\s*\d\+[.)]\s*//' | \
        sed 's/^\s*\[ \]\s*//' | \
        sed 's/^\s*任务\s*\d*[:：]?\s*//' | \
        sed 's/^\s*子任务\s*[:：]?\s*//' | \
        sed 's/^/"/' | \
        sed 's/$/",/' | \
        sed '$s/,$//'
    
    # 如果没有匹配到，尝试提取所有以连字符或星号开头的行
    if [ $? -ne 0 ]; then
        echo "$output" | grep -E '^\s*[-*]\s+' | \
            sed 's/^\s*[-*]\s*//' | \
            sed 's/^/"/' | \
            sed 's/$/",/' | \
            sed '$s/,$//'
    fi
}

prepend_tasks() {
    local new_tasks="$1"
    
    if [ -z "$new_tasks" ]; then
        return
    fi
    
    local temp_array=()
    while IFS= read -r task; do
        if [ -n "$task" ]; then
            temp_array+=("$task")
        fi
    done <<< "$new_tasks"
    
    local current_tasks=$(cat "$TASKS_FILE")
    
    for task in "${temp_array[@]}"; do
        current_tasks=$(echo "$current_tasks" | jq --arg t "$task" '[$t] + .')
    done
    
    echo "$current_tasks" > "$TASKS_FILE"
}

get_next_task() {
    cat "$TASKS_FILE" | jq -r '.[0] // empty'
}

remove_task() {
    cat "$TASKS_FILE" | jq '.[1:]' > "$TASKS_FILE.tmp"
    mv "$TASKS_FILE.tmp" "$TASKS_FILE"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

git_pull_and_handle_conflicts() {
    log "执行: git pull"
    git pull
    
    if [ $? -ne 0 ]; then
        log "Git pull 失败，检查是否有冲突..."
        
        # 检查是否有冲突
        local status_output=$(git status)
        if echo "$status_output" | grep -i "conflict" > /dev/null; then
            log "发现冲突，尝试自动解决..."
            
            # 尝试使用 theirs 策略解决冲突
            if git checkout --theirs .; then
                log "冲突已自动解决（使用远程版本）"
            else
                log "自动解决冲突失败，调用 Claude 解决..."
                
                # 调用 Claude 解决冲突
                local conflict_files=$(git diff --name-only --diff-filter=U)
                if [ -n "$conflict_files" ]; then
                    local prompt="我在运行 git pull 时遇到了冲突，请帮我解决。\n\n冲突文件：\n$conflict_files\n\n请提供解决冲突的步骤。"
                    
                    log "调用 Claude 解决冲突..."
                    local result=$(claude -p --dangerously-skip-permissions "$prompt" 2>&1)
                    log "Claude 提供的冲突解决建议:"
                    log "$result"
                fi
            fi
        else
            log "Git pull 失败，可能是其他原因"
        fi
    else
        log "Git pull 成功"
    fi
}

git_commit_and_push() {
    local task="$1"
    log "检查 git 变更..."
    
    local changes=$(git status --porcelain)
    if [ -z "$changes" ]; then
        log "没有文件变更，跳过 git 提交"
        return
    fi
    
    log "执行: git add ."
    git add .
    
    local commit_msg="update: $task"
    if [ ${#task} -gt 50 ]; then
        commit_msg="update: ${task:0:50}..."
    fi
    log "执行: git commit -m \"$commit_msg\""
    git commit -m "$commit_msg"
    
    log "执行: git push"
    git push
    
    log "Git 操作完成"
}

main() {
    init_tasks
    
    log "开始执行任务循环"
    
    while true; do
        task_count=$(cat "$TASKS_FILE" | jq 'length')
        
        if [ "$task_count" -eq 0 ]; then
            log "任务列表为空，生成新任务..."
            
            local system_prompt="你是一个任务执行助手。在完成任务后，如果还有后续工作需要完成，请以列表形式输出子任务。

子任务格式要求：
- 使用 - 或 * 开头
- 每个子任务占一行
- 简洁明确，便于后续执行

示例：
- 完成训练计划章节的编写
- 添加跑步技术章节内容
- 审核并优化现有内容

请先完成当前任务，然后根据需要输出子任务列表。

"
            
            log "执行命令: claude -p --dangerously-skip-permissions \"\""
            output=$(claude -p --dangerously-skip-permissions "$system_prompt" 2>&1)
            echo "$output" >> "$LOG_FILE"
            
            new_tasks=$(extract_tasks "$output")
            
            if [ -n "$new_tasks" ]; then
                log "提取到新任务，添加到任务列表"
                prepend_tasks "$new_tasks"
            else
                log "未提取到新任务，结束循环"
                break
            fi
        fi
        
        task=$(get_next_task)
        
        if [ -z "$task" ]; then
            log "没有更多任务，结束循环"
            break
        fi
        
        # 执行 git pull 并处理冲突
        git_pull_and_handle_conflicts
        
        log "执行任务: $task"
        
        local system_prompt="你是一个任务执行助手。在完成任务后，如果还有后续工作需要完成，请以列表形式输出子任务。

子任务格式要求：
- 使用 - 或 * 开头
- 每个子任务占一行
- 简洁明确，便于后续执行

示例：
- 完成训练计划章节的编写
- 添加跑步技术章节内容
- 审核并优化现有内容

请先完成当前任务，然后根据需要输出子任务列表。

"
        
        local full_prompt="$system_prompt$task"
        log "执行命令: claude -p --dangerously-skip-permissions \"$task\""
        output=$(claude -p --dangerously-skip-permissions "$full_prompt" 2>&1)
        echo "$output" >> "$LOG_FILE"
        
        new_tasks=$(extract_tasks "$output")
        
        if [ -n "$new_tasks" ]; then
            log "提取到新任务，插入到任务列表头部"
            prepend_tasks "$new_tasks"
        fi
        
        git_commit_and_push "$task"
        remove_task
        log "任务完成，剩余任务数: $(cat "$TASKS_FILE" | jq 'length')"
    done
    
    log "所有任务执行完成"
}

main "$@"
