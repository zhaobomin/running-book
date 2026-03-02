#!/usr/bin/env python3
"""
自动任务执行脚本
1. 通过 claude -p 生成任务列表
2. 格式化并存储任务
3. 循环执行任务，直到没有新任务
"""

import json
import subprocess
import re
import os
from datetime import datetime

TASKS_FILE = "tasks/tasks.json"
LOG_FILE = "tasks/execution.log"

os.makedirs("tasks", exist_ok=True)

def log(message):
    """记录日志"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_line = f"[{timestamp}] {message}"
    print(log_line)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(log_line + "\n")

def load_tasks():
    """加载任务列表"""
    if os.path.exists(TASKS_FILE):
        with open(TASKS_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return []

def save_tasks(tasks):
    """保存任务列表"""
    with open(TASKS_FILE, "w", encoding="utf-8") as f:
        json.dump(tasks, f, ensure_ascii=False, indent=2)

def extract_tasks(text):
    """从文本中提取任务"""
    tasks = []
    
    patterns = [
        r'^\s*[-*]\s+(.+)$',
        r'^\s*\d+[.)]\s+(.+)$',
        r'^\s*\[ \]\s+(.+)$',
    ]
    
    for line in text.split('\n'):
        line = line.strip()
        if not line:
            continue
        
        for pattern in patterns:
            match = re.match(pattern, line)
            if match:
                task = match.group(1).strip()
                if task and not task.startswith('#'):
                    tasks.append(task)
                break
    
    return tasks

def run_claude(prompt):
    """执行 claude 命令"""
    try:
        system_prompt = """你是一个任务执行助手。在完成任务后，如果还有后续工作需要完成，请以列表形式输出子任务。

子任务格式要求：
- 使用 - 或 * 开头
- 每个子任务占一行
- 简洁明确，便于后续执行

示例：
- 完成训练计划章节的编写
- 添加跑步技术章节内容
- 审核并优化现有内容

请先完成当前任务，然后根据需要输出子任务列表。

"""
        
        full_prompt = system_prompt + prompt
        cmd = ["claude", "-p", "--dangerously-skip-permissions", full_prompt]
        result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
        return result.stdout + result.stderr
    except Exception as e:
        log(f"执行 claude 命令出错: {e}")
        return ""

def git_commit_and_push(task):
    """执行 git 操作：add, commit, push"""
    try:
        log("检查 git 变更...")
        
        # 检查是否有变更
        result = subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True)
        if not result.stdout.strip():
            log("没有文件变更，跳过 git 提交")
            return
        
        # git add .
        log("执行: git add .")
        subprocess.run(["git", "add", "."], check=True)
        
        # git commit
        commit_msg = f"update: {task[:50]}..." if len(task) > 50 else f"update: {task}"
        log(f"执行: git commit -m \"{commit_msg}\"")
        subprocess.run(["git", "commit", "-m", commit_msg], check=True)
        
        # git push
        log("执行: git push")
        subprocess.run(["git", "push"], check=True)
        
        log("Git 操作完成")
    except subprocess.CalledProcessError as e:
        log(f"Git 操作出错: {e}")
    except Exception as e:
        log(f"Git 操作异常: {e}")

def main():
    """主循环"""
    log("开始执行任务循环")
    
    tasks = load_tasks()
    
    while True:
        if not tasks:
            log("任务列表为空，生成新任务...")
            
            log("执行: claude -p --dangerously-skip-permissions \"\"")
            output = run_claude("")
            
            new_tasks = extract_tasks(output)
            
            if new_tasks:
                log(f"提取到 {len(new_tasks)} 个新任务")
                tasks = new_tasks + tasks
                save_tasks(tasks)
            else:
                log("未提取到新任务，结束循环")
                break
        
        if not tasks:
            log("没有更多任务，结束循环")
            break
        
        task = tasks.pop(0)
        save_tasks(tasks)
        
        log(f"执行任务: {task}")
        log(f"执行: claude -p --dangerously-skip-permissions \"{task}\"")
        output = run_claude(task)
        
        new_tasks = extract_tasks(output)
        
        if new_tasks:
            log(f"提取到 {len(new_tasks)} 个新任务，插入到任务列表头部")
            tasks = new_tasks + tasks
            save_tasks(tasks)
        
        git_commit_and_push(task)
        log(f"任务完成，剩余任务数: {len(tasks)}")
    
    log("所有任务执行完成")

if __name__ == "__main__":
    main()
